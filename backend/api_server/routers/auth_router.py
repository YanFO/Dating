"""Authentication Router

Mobile Google / Apple OAuth + session management.
Uses shared lens_account database (PascalCase Prisma tables).
"""

import json
import uuid
from datetime import datetime, timedelta
from pathlib import Path

import httpx
import jwt
from quart import Blueprint, request, jsonify, current_app
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

import structlog

from clients.auth_db_client import get_auth_db_session
from services.id_service import generate_cuid

logger = structlog.get_logger()

bp = Blueprint("auth", __name__, url_prefix="/auth")

# ── Apple Sign In constants ──────────────────────────────────────
_apple_keys_cache: dict = {"keys": None, "fetched_at": None}
APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"
APPLE_KEYS_CACHE_TTL = timedelta(hours=24)
APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token"

_apple_client_secret_cache: dict = {"secret": None, "expires_at": None}
_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent


# ── Helpers ──────────────────────────────────────────────────────

def _get_settings():
    return current_app.config["SETTINGS"]


def get_google_client_ids() -> list[str]:
    """Get list of valid Google Client IDs from settings."""
    settings = _get_settings()
    client_ids = []
    if settings.AUTH_GOOGLE_ID:
        client_ids.append(settings.AUTH_GOOGLE_ID)
    if settings.GOOGLE_MOBILE_CLIENT_IDS:
        ids = [cid.strip() for cid in settings.GOOGLE_MOBILE_CLIENT_IDS.split(",") if cid.strip()]
        client_ids.extend(ids)
    return client_ids


async def _ensure_business_db_user(user_id: str, name: str, email: str) -> None:
    """Sync user to lens_dating.users (business DB) after auth."""
    pg_session_factory = current_app.config["pg_session_factory"]
    async with pg_session_factory() as session:
        from sqlalchemy import text
        await session.execute(
            text(
                'INSERT INTO users (id, email, display_name, role, created_at, updated_at) '
                'VALUES (:id, :email, :name, \'user\', NOW(), NOW()) '
                'ON CONFLICT (id) DO UPDATE SET '
                'email = COALESCE(EXCLUDED.email, users.email), '
                'display_name = COALESCE(EXCLUDED.display_name, users.display_name), '
                'updated_at = NOW()'
            ),
            {"id": user_id, "email": email, "name": name},
        )
        await session.commit()
    logger.info("business_db_user_synced", user_id=user_id)


# ── Google Mobile Auth ───────────────────────────────────────────

@bp.route("/mobile/google", methods=["POST"])
async def mobile_google_auth():
    """
    Mobile Google OAuth endpoint.

    Request: { "idToken": "..." }
    Response: { "success": true, "sessionToken": "...", "user": { ... } }
    """
    try:
        data = await request.get_json()
        id_token_str = data.get("idToken")

        if not id_token_str:
            return jsonify({"success": False, "error": "Missing idToken"}), 400

        google_client_ids = get_google_client_ids()
        if not google_client_ids:
            logger.error("no_google_client_ids")
            return jsonify({"success": False, "error": "Server configuration error"}), 500

        try:
            idinfo = id_token.verify_oauth2_token(
                id_token_str,
                google_requests.Request(),
                audience=None,
            )
            if idinfo.get("aud") not in google_client_ids:
                logger.warning("invalid_google_audience", aud=idinfo.get("aud"))
                return jsonify({"success": False, "error": "Invalid Google token"}), 401
        except ValueError as e:
            logger.error("google_token_verify_failed", error=str(e))
            return jsonify({"success": False, "error": "Invalid Google token"}), 401

        email = idinfo.get("email")
        name = idinfo.get("name")
        picture = idinfo.get("picture")
        google_id = idinfo.get("sub")

        if not email:
            return jsonify({"success": False, "error": "Invalid token payload"}), 401

        async with get_auth_db_session() as session:
            result = await session.execute(
                'SELECT id, email, name, image FROM "User" WHERE email = :email',
                {"email": email},
            )
            user_row = result.fetchone()
            now = datetime.utcnow()

            if not user_row:
                user_id = generate_cuid()
                username = name or email.split("@")[0]

                await session.execute(
                    'INSERT INTO "User" (id, email, name, image, "emailVerified", "createdAt", "updatedAt") '
                    'VALUES (:id, :email, :name, :image, :email_verified, :created_at, :updated_at)',
                    {
                        "id": user_id, "email": email, "name": username, "image": picture,
                        "email_verified": now, "created_at": now, "updated_at": now,
                    },
                )
                await session.execute(
                    'INSERT INTO "Account" ("userId", type, provider, "providerAccountId", "createdAt", "updatedAt") '
                    'VALUES (:user_id, \'oauth\', \'google\', :provider_account_id, :created_at, :updated_at)',
                    {
                        "user_id": user_id, "provider_account_id": google_id,
                        "created_at": now, "updated_at": now,
                    },
                )
                user = {"id": user_id, "email": email, "name": username, "image": picture}
            else:
                user_id = user_row[0]
                await session.execute(
                    'UPDATE "User" SET name = COALESCE(:name, name), '
                    'image = COALESCE(:image, image), "updatedAt" = :updated_at WHERE id = :id',
                    {"id": user_id, "name": name, "image": picture, "updated_at": now},
                )
                user = {
                    "id": user_id, "email": user_row[1],
                    "name": name or user_row[2], "image": picture or user_row[3],
                }

            # Single-device login: clear old sessions
            await session.execute(
                'DELETE FROM "Session" WHERE "userId" = :user_id',
                {"user_id": user_id},
            )

            session_token = str(uuid.uuid4())
            expires = now + timedelta(days=30)
            await session.execute(
                'INSERT INTO "Session" ("sessionToken", "userId", expires, "createdAt", "updatedAt") '
                'VALUES (:session_token, :user_id, :expires, :created_at, :updated_at)',
                {
                    "session_token": session_token, "user_id": user_id,
                    "expires": expires, "created_at": now, "updated_at": now,
                },
            )

        await _ensure_business_db_user(user["id"], user.get("name") or user.get("email", ""), user.get("email", ""))

        return jsonify({"success": True, "sessionToken": session_token, "user": user})

    except Exception as e:
        logger.exception("mobile_google_auth_error", error=str(e))
        return jsonify({"success": False, "error": "Authentication failed"}), 500


# ── Google Web Auth (accessToken) ─────────────────────────────────

@bp.route("/web/google", methods=["POST"])
async def web_google_auth():
    """
    Web Google OAuth endpoint — uses accessToken to fetch user info.

    Request: { "accessToken": "..." }
    Response: { "success": true, "sessionToken": "...", "user": { ... } }
    """
    try:
        data = await request.get_json()
        access_token = data.get("accessToken")

        if not access_token:
            return jsonify({"success": False, "error": "Missing accessToken"}), 400

        # Use accessToken to get user info from Google
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                "https://www.googleapis.com/oauth2/v3/userinfo",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            if resp.status_code != 200:
                logger.error("google_userinfo_failed", status=resp.status_code)
                return jsonify({"success": False, "error": "Invalid access token"}), 401
            userinfo = resp.json()

        email = userinfo.get("email")
        name = userinfo.get("name")
        picture = userinfo.get("picture")
        google_id = userinfo.get("sub")

        if not email or not google_id:
            return jsonify({"success": False, "error": "Invalid token payload"}), 401

        async with get_auth_db_session() as session:
            result = await session.execute(
                'SELECT id, email, name, image FROM "User" WHERE email = :email',
                {"email": email},
            )
            user_row = result.fetchone()
            now = datetime.utcnow()

            if not user_row:
                user_id = generate_cuid()
                username = name or email.split("@")[0]

                await session.execute(
                    'INSERT INTO "User" (id, email, name, image, "emailVerified", "createdAt", "updatedAt") '
                    'VALUES (:id, :email, :name, :image, :email_verified, :created_at, :updated_at)',
                    {
                        "id": user_id, "email": email, "name": username, "image": picture,
                        "email_verified": now, "created_at": now, "updated_at": now,
                    },
                )
                await session.execute(
                    'INSERT INTO "Account" ("userId", type, provider, "providerAccountId", "createdAt", "updatedAt") '
                    'VALUES (:user_id, \'oauth\', \'google\', :provider_account_id, :created_at, :updated_at)',
                    {
                        "user_id": user_id, "provider_account_id": google_id,
                        "created_at": now, "updated_at": now,
                    },
                )
                user = {"id": user_id, "email": email, "name": username, "image": picture}
            else:
                user_id = user_row[0]
                await session.execute(
                    'UPDATE "User" SET name = COALESCE(:name, name), '
                    'image = COALESCE(:image, image), "updatedAt" = :updated_at WHERE id = :id',
                    {"id": user_id, "name": name, "image": picture, "updated_at": now},
                )
                user = {
                    "id": user_id, "email": user_row[1],
                    "name": name or user_row[2], "image": picture or user_row[3],
                }

            # Single-device login: clear old sessions
            await session.execute(
                'DELETE FROM "Session" WHERE "userId" = :user_id',
                {"user_id": user_id},
            )

            session_token = str(uuid.uuid4())
            expires = now + timedelta(days=30)
            await session.execute(
                'INSERT INTO "Session" ("sessionToken", "userId", expires, "createdAt", "updatedAt") '
                'VALUES (:session_token, :user_id, :expires, :created_at, :updated_at)',
                {
                    "session_token": session_token, "user_id": user_id,
                    "expires": expires, "created_at": now, "updated_at": now,
                },
            )

        await _ensure_business_db_user(user["id"], user.get("name") or user.get("email", ""), user.get("email", ""))

        return jsonify({"success": True, "sessionToken": session_token, "user": user})

    except Exception as e:
        logger.exception("web_google_auth_error", error=str(e))
        return jsonify({"success": False, "error": "Authentication failed"}), 500


# ── Apple Sign In ────────────────────────────────────────────────

def _get_apple_private_key() -> str:
    """Read Apple .p8 private key file."""
    settings = _get_settings()
    if settings.APPLE_PRIVATE_KEY_PATH:
        key_path = Path(settings.APPLE_PRIVATE_KEY_PATH)
    else:
        data_dir = _PROJECT_ROOT / "data"
        p8_files = list(data_dir.glob("AuthKey_*.p8"))
        if not p8_files:
            raise FileNotFoundError("Apple .p8 private key not found")
        key_path = p8_files[0]

    with open(key_path, "r") as f:
        return f.read()


def generate_apple_client_secret() -> str:
    """Generate Apple Client Secret JWT (ES256), cached 30 days."""
    settings = _get_settings()
    now = datetime.utcnow()

    if (
        _apple_client_secret_cache["secret"] is not None
        and _apple_client_secret_cache["expires_at"] is not None
        and now < _apple_client_secret_cache["expires_at"]
    ):
        return _apple_client_secret_cache["secret"]

    if not settings.APPLE_TEAM_ID or not settings.APPLE_KEY_ID or not settings.APPLE_BUNDLE_ID:
        raise ValueError("Missing Apple Sign In config (APPLE_TEAM_ID / APPLE_KEY_ID / APPLE_BUNDLE_ID)")

    private_key = _get_apple_private_key()
    expires = now + timedelta(days=30)

    headers = {"kid": settings.APPLE_KEY_ID, "alg": "ES256"}
    payload = {
        "iss": settings.APPLE_TEAM_ID,
        "iat": int(now.timestamp()),
        "exp": int(expires.timestamp()),
        "aud": APPLE_ISSUER,
        "sub": settings.APPLE_BUNDLE_ID,
    }

    client_secret = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
    _apple_client_secret_cache["secret"] = client_secret
    _apple_client_secret_cache["expires_at"] = expires - timedelta(hours=1)
    logger.info("apple_client_secret_generated")
    return client_secret


async def validate_apple_authorization_code(authorization_code: str) -> dict | None:
    """Validate Apple authorization code via token endpoint."""
    settings = _get_settings()
    try:
        client_secret = generate_apple_client_secret()
    except (ValueError, FileNotFoundError) as e:
        logger.warning("apple_client_secret_skip", error=str(e))
        return None

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                APPLE_TOKEN_URL,
                data={
                    "client_id": settings.APPLE_BUNDLE_ID,
                    "client_secret": client_secret,
                    "code": authorization_code,
                    "grant_type": "authorization_code",
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            if resp.status_code == 200:
                logger.info("apple_code_validated")
                return resp.json()
            logger.warning("apple_code_validation_failed", status=resp.status_code)
            return None
    except Exception as e:
        logger.warning("apple_code_validation_error", error=str(e))
        return None


async def get_apple_public_keys() -> list[dict]:
    """Fetch Apple JWK public keys (24h cache)."""
    now = datetime.utcnow()

    if (
        _apple_keys_cache["keys"] is not None
        and _apple_keys_cache["fetched_at"] is not None
        and now - _apple_keys_cache["fetched_at"] < APPLE_KEYS_CACHE_TTL
    ):
        return _apple_keys_cache["keys"]

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(APPLE_KEYS_URL)
            resp.raise_for_status()
            keys = resp.json()["keys"]
        _apple_keys_cache["keys"] = keys
        _apple_keys_cache["fetched_at"] = now
        logger.info("apple_keys_refreshed", count=len(keys))
        return keys
    except Exception as e:
        logger.warning("apple_keys_fetch_failed", error=str(e))
        key_path = _PROJECT_ROOT / "data" / "keys.json"
        if key_path.exists():
            with open(key_path, "r") as f:
                keys = json.load(f)["keys"]
            _apple_keys_cache["keys"] = keys
            _apple_keys_cache["fetched_at"] = now
            return keys
        raise


def decode_apple_identity_token(identity_token: str, audience: list[str]) -> dict:
    """Decode and verify Apple Identity Token (RS256 JWT)."""
    from jwt.algorithms import RSAAlgorithm

    unverified_header = jwt.get_unverified_header(identity_token)
    kid = unverified_header.get("kid")
    if not kid:
        raise ValueError("Token header missing kid")

    apple_keys = _apple_keys_cache.get("keys")
    if not apple_keys:
        raise ValueError("Apple public keys not loaded")

    matching_key = next((k for k in apple_keys if k.get("kid") == kid), None)
    if not matching_key:
        raise ValueError(f"No matching Apple public key (kid={kid})")

    public_key = RSAAlgorithm.from_jwk(json.dumps(matching_key))
    return jwt.decode(
        identity_token,
        public_key,
        algorithms=["RS256"],
        audience=audience,
        issuer=APPLE_ISSUER,
    )


@bp.route("/mobile/apple", methods=["POST"])
async def mobile_apple_auth():
    """
    Mobile Apple Sign In endpoint.

    Request: { "identityToken", "authorizationCode", "fullName"?, "email"?, "platform" }
    Response: { "success": true, "sessionToken": "...", "user": { ... } }
    """
    try:
        data = await request.get_json()
        identity_token = data.get("identityToken")
        authorization_code = data.get("authorizationCode")
        full_name = data.get("fullName")
        request_email = data.get("email")

        if not identity_token or not authorization_code:
            return jsonify({"success": False, "error": "Missing identityToken or authorizationCode"}), 400

        settings = _get_settings()
        apple_audience = []
        if settings.APPLE_BUNDLE_ID:
            apple_audience.append(settings.APPLE_BUNDLE_ID)
        if settings.APPLE_SERVICE_ID:
            apple_audience.append(settings.APPLE_SERVICE_ID)

        if not apple_audience:
            logger.error("no_apple_audience_configured")
            return jsonify({"success": False, "error": "Server configuration error"}), 500

        await get_apple_public_keys()

        try:
            payload = decode_apple_identity_token(identity_token, apple_audience)
        except ValueError as e:
            logger.error("apple_token_invalid", error=str(e))
            return jsonify({"success": False, "error": "Invalid Apple token"}), 401
        except jwt.ExpiredSignatureError:
            return jsonify({"success": False, "error": "Apple token expired"}), 401
        except jwt.InvalidTokenError as e:
            logger.error("apple_token_error", error=str(e))
            return jsonify({"success": False, "error": "Invalid Apple token"}), 401

        await validate_apple_authorization_code(authorization_code)

        apple_user_id = payload.get("sub")
        email = payload.get("email") or request_email
        email_verified = payload.get("email_verified", False)
        if isinstance(email_verified, str):
            email_verified = email_verified.lower() == "true"

        if not apple_user_id or not email:
            return jsonify({"success": False, "error": "Invalid token payload"}), 401

        # Parse fullName (string or dict)
        name = None
        if full_name:
            if isinstance(full_name, str):
                name = full_name.strip() or None
            elif isinstance(full_name, dict):
                given = full_name.get("givenName", "") or ""
                family = full_name.get("familyName", "") or ""
                name = f"{given} {family}".strip() or None

        async with get_auth_db_session() as session:
            # Look up existing Apple account
            account_result = await session.execute(
                'SELECT a."userId", u.email, u.name, u.image '
                'FROM "Account" a JOIN "User" u ON a."userId" = u.id '
                'WHERE a.provider = \'apple\' AND a."providerAccountId" = :apple_user_id',
                {"apple_user_id": apple_user_id},
            )
            existing_account = account_result.fetchone()
            now = datetime.utcnow()

            if existing_account:
                user_id = existing_account[0]
                if name:
                    await session.execute(
                        'UPDATE "User" SET name = :name, "updatedAt" = :updated_at WHERE id = :id',
                        {"id": user_id, "name": name, "updated_at": now},
                    )
                user = {
                    "id": user_id, "email": existing_account[1],
                    "name": name or existing_account[2], "image": existing_account[3],
                }
            else:
                # Check if user exists by email
                result = await session.execute(
                    'SELECT id, email, name, image FROM "User" WHERE email = :email',
                    {"email": email},
                )
                user_row = result.fetchone()

                if user_row:
                    user_id = user_row[0]
                    if name:
                        await session.execute(
                            'UPDATE "User" SET name = :name, "updatedAt" = :updated_at WHERE id = :id',
                            {"id": user_id, "name": name, "updated_at": now},
                        )
                    await session.execute(
                        'INSERT INTO "Account" ("userId", type, provider, "providerAccountId", "createdAt", "updatedAt") '
                        'VALUES (:user_id, \'oauth\', \'apple\', :provider_account_id, :created_at, :updated_at) '
                        'ON CONFLICT (provider, "providerAccountId") DO UPDATE SET "updatedAt" = :updated_at',
                        {
                            "user_id": user_id, "provider_account_id": apple_user_id,
                            "created_at": now, "updated_at": now,
                        },
                    )
                    user = {
                        "id": user_id, "email": user_row[1],
                        "name": name or user_row[2], "image": user_row[3],
                    }
                else:
                    user_id = generate_cuid()
                    username = name or email.split("@")[0]
                    await session.execute(
                        'INSERT INTO "User" (id, email, name, image, "emailVerified", "createdAt", "updatedAt") '
                        'VALUES (:id, :email, :name, :image, :email_verified, :created_at, :updated_at)',
                        {
                            "id": user_id, "email": email, "name": username, "image": None,
                            "email_verified": now if email_verified else None,
                            "created_at": now, "updated_at": now,
                        },
                    )
                    await session.execute(
                        'INSERT INTO "Account" ("userId", type, provider, "providerAccountId", "createdAt", "updatedAt") '
                        'VALUES (:user_id, \'oauth\', \'apple\', :provider_account_id, :created_at, :updated_at)',
                        {
                            "user_id": user_id, "provider_account_id": apple_user_id,
                            "created_at": now, "updated_at": now,
                        },
                    )
                    user = {"id": user_id, "email": email, "name": username, "image": None}

            # Single-device login
            await session.execute(
                'DELETE FROM "Session" WHERE "userId" = :user_id',
                {"user_id": user_id},
            )

            session_token = str(uuid.uuid4())
            expires = now + timedelta(days=30)
            await session.execute(
                'INSERT INTO "Session" ("sessionToken", "userId", expires, "createdAt", "updatedAt") '
                'VALUES (:session_token, :user_id, :expires, :created_at, :updated_at)',
                {
                    "session_token": session_token, "user_id": user_id,
                    "expires": expires, "created_at": now, "updated_at": now,
                },
            )

        await _ensure_business_db_user(user["id"], user.get("name") or user.get("email", ""), user.get("email", ""))

        logger.info("apple_auth_success", user_id=user["id"])
        return jsonify({"success": True, "sessionToken": session_token, "user": user})

    except Exception as e:
        logger.exception("mobile_apple_auth_error", error=str(e))
        return jsonify({"success": False, "error": "Authentication failed"}), 500


# ── Session Management ───────────────────────────────────────────

@bp.route("/session/validate", methods=["POST"])
async def validate_session():
    """
    Validate session token.

    Request: { "sessionToken": "..." }
    Response: { "success": true, "valid": true/false, "user": { ... } }
    """
    try:
        data = await request.get_json()
        session_token = data.get("sessionToken")

        if not session_token:
            return jsonify({"success": False, "error": "Missing sessionToken"}), 400

        async with get_auth_db_session() as session:
            result = await session.execute(
                'SELECT u.id, u.email, u.name, u.image, s.expires '
                'FROM "Session" s JOIN "User" u ON s."userId" = u.id '
                'WHERE s."sessionToken" = :session_token',
                {"session_token": session_token},
            )
            row = result.fetchone()

            if not row:
                return jsonify({"success": True, "valid": False})

            expires = row[4]
            if expires.replace(tzinfo=None) < datetime.utcnow():
                return jsonify({"success": True, "valid": False})

            return jsonify({
                "success": True,
                "valid": True,
                "user": {"id": row[0], "email": row[1], "name": row[2], "image": row[3]},
            })

    except Exception as e:
        logger.exception("session_validate_error", error=str(e))
        return jsonify({"success": False, "error": "Validation failed"}), 500


@bp.route("/logout", methods=["POST"])
async def logout():
    """
    Logout — delete session.

    Request: { "sessionToken": "..." }
    """
    try:
        data = await request.get_json()
        session_token = data.get("sessionToken")

        if not session_token:
            return jsonify({"success": False, "error": "Missing sessionToken"}), 400

        async with get_auth_db_session() as session:
            await session.execute(
                'DELETE FROM "Session" WHERE "sessionToken" = :session_token',
                {"session_token": session_token},
            )

        return jsonify({"success": True, "message": "Logged out successfully"})

    except Exception as e:
        logger.exception("logout_error", error=str(e))
        return jsonify({"success": False, "error": "Logout failed"}), 500


# ── Delete User ──────────────────────────────────────────────────

@bp.route("/user", methods=["DELETE"])
async def delete_user():
    """
    Delete all user data from lens_dating (business DB).
    Preserves lens_account records (User/Account) for re-registration.

    Request: { "sessionToken": "..." }
    """
    try:
        data = await request.get_json()
        session_token = data.get("sessionToken")

        if not session_token:
            return jsonify({"success": False, "error": "Missing sessionToken"}), 400

        # Validate session and get user_id
        async with get_auth_db_session() as session:
            result = await session.execute(
                'SELECT u.id, u.email FROM "Session" s '
                'JOIN "User" u ON s."userId" = u.id '
                'WHERE s."sessionToken" = :session_token',
                {"session_token": session_token},
            )
            row = result.fetchone()

            if not row:
                return jsonify({"success": False, "error": "Invalid or expired session"}), 401

            user_id = row[0]

        # Delete from lens_dating business DB (child tables first)
        pg_session_factory = current_app.config["pg_session_factory"]
        async with pg_session_factory() as db_session:
            from sqlalchemy import text

            # FK order: children → parents
            await db_session.execute(text('DELETE FROM love_coach_messages WHERE conversation_id IN (SELECT id FROM love_coach_conversations WHERE user_id = :uid)'), {"uid": user_id})
            await db_session.execute(text('DELETE FROM love_coach_conversations WHERE user_id = :uid'), {"uid": user_id})
            await db_session.execute(text('DELETE FROM analysis_logs WHERE user_id = :uid'), {"uid": user_id})
            await db_session.execute(text('DELETE FROM date_reports WHERE user_id = :uid'), {"uid": user_id})
            await db_session.execute(text('DELETE FROM match_memories WHERE user_id = :uid'), {"uid": user_id})
            await db_session.execute(text('DELETE FROM matches WHERE user_id = :uid'), {"uid": user_id})
            await db_session.execute(text('DELETE FROM sessions WHERE user_id = :uid'), {"uid": user_id})
            await db_session.execute(text('DELETE FROM user_personas WHERE user_id = :uid'), {"uid": user_id})
            await db_session.execute(text('DELETE FROM jobs WHERE user_id = :uid'), {"uid": user_id})
            await db_session.execute(text('DELETE FROM users WHERE id = :uid'), {"uid": user_id})

            await db_session.commit()

        # Delete auth session
        async with get_auth_db_session() as session:
            await session.execute(
                'DELETE FROM "Session" WHERE "userId" = :user_id',
                {"user_id": user_id},
            )

        logger.info("user_deleted", user_id=user_id)
        return jsonify({"success": True, "message": "User data deleted successfully", "userId": user_id})

    except Exception as e:
        logger.exception("delete_user_error", error=str(e))
        return jsonify({"success": False, "error": "Failed to delete user data"}), 500
