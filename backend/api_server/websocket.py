import asyncio

import orjson
import structlog
from quart import Quart, websocket

from services.id_service import generate_request_id

logger = structlog.get_logger()


def register_websocket_routes(app: Quart) -> None:

    @app.websocket("/ws/health")
    async def ws_health():
        data = await websocket.receive()
        await websocket.send("pong")

    @app.websocket("/ws/voice-coach/<session_id>")
    async def voice_coach_ws(session_id: str):
        request_id = generate_request_id()
        log = logger.bind(request_id=request_id, session_id=session_id)

        voice_service = app.config.get("voice_coach_service")
        stream_service = app.config.get("stream_service")

        if not voice_service or not stream_service:
            await websocket.send(
                orjson.dumps(
                    {"type": "error", "payload": {"message": "Voice coach not enabled"}}
                ).decode()
            )
            return

        log.info("voice_coach_ws_connected")

        try:
            session = await voice_service.create_session(session_id, request_id)
        except Exception as e:
            log.error("voice_coach_session_create_failed", error=str(e))
            await websocket.send(
                orjson.dumps(
                    {"type": "error", "payload": {"message": str(e)}}
                ).decode()
            )
            return

        queue = await stream_service.subscribe(session_id)

        await websocket.send(
            orjson.dumps(
                {
                    "type": "session_ready",
                    "session_id": session_id,
                    "request_id": request_id,
                }
            ).decode()
        )

        async def client_to_openai():
            try:
                while True:
                    raw = await websocket.receive()
                    msg = orjson.loads(raw)
                    msg_type = msg.get("type", "")
                    if msg_type == "audio":
                        await voice_service.relay_audio(
                            session_id, msg.get("payload", "")
                        )
                    elif msg_type == "close":
                        break
            except Exception as e:
                log.debug("client_to_openai_ended", reason=str(e))

        async def openai_to_client():
            try:
                while True:
                    event = await asyncio.wait_for(queue.get(), timeout=60.0)
                    await websocket.send(orjson.dumps(event).decode())
                    if event.get("type") in ("disconnected", "error"):
                        break
            except asyncio.TimeoutError:
                log.warning("openai_to_client_timeout")
            except Exception as e:
                log.debug("openai_to_client_ended", reason=str(e))

        try:
            await asyncio.gather(client_to_openai(), openai_to_client())
        except Exception:
            pass
        finally:
            await stream_service.unsubscribe(session_id, queue)
            await voice_service.close_session(session_id)
            log.info("voice_coach_ws_disconnected")
