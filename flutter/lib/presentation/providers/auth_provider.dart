import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../data/models/auth_models.dart';
import 'core_providers.dart';
import 'google_sign_in_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_web_helper.dart' as web_sign_in;

const _kSessionTokenKey = 'auth_session_token';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    apiClient: ref.watch(apiClientProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  AuthNotifier({
    required ApiClient apiClient,
    required SharedPreferences prefs,
  })  : _apiClient = apiClient,
        _prefs = prefs,
        super(const AuthState());

  /// Initialize auth state: read stored token and validate session.
  Future<void> init() async {
    final token = _prefs.getString(_kSessionTokenKey);
    if (token == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.authSessionValidate,
      data: {'sessionToken': token},
      fromJson: (d) => d as Map<String, dynamic>,
    );

    result.fold(
      (error) {
        // Token invalid or network error — stay anonymous
        _prefs.remove(_kSessionTokenKey);
        state = state.copyWith(isLoading: false, clearUser: true, clearToken: true);
      },
      (data) {
        if (data['valid'] == true && data['user'] != null) {
          state = AuthState(
            user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
            sessionToken: token,
          );
        } else {
          _prefs.remove(_kSessionTokenKey);
          state = const AuthState();
        }
      },
    );
  }

  /// Google Sign In flow.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (kIsWeb) {
        return await _signInWithGoogleWeb();
      } else {
        return await _signInWithGoogleMobile();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Google Sign In — mobile (idToken flow).
  Future<bool> _signInWithGoogleMobile() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: '315860625911-d94mos54u50nsv7tkbb888obdlrqbabs.apps.googleusercontent.com',
    );
    final account = await googleSignIn.signIn();
    if (account == null) {
      state = state.copyWith(isLoading: false);
      return false;
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      state = state.copyWith(isLoading: false, error: 'Failed to get Google ID token');
      return false;
    }

    return _authenticateWithBackend(
      ApiEndpoints.authGoogleMobile,
      {'idToken': idToken},
    );
  }

  /// Google Sign In — web (GIS One Tap → idToken).
  Future<bool> _signInWithGoogleWeb() async {
    try {
      final idToken = await web_sign_in.googleSignInWeb();
      if (idToken == null) {
        state = state.copyWith(isLoading: false, error: 'Google sign-in was cancelled');
        return false;
      }

      return _authenticateWithBackend(
        ApiEndpoints.authGoogleMobile,
        {'idToken': idToken},
      );
    } catch (e, st) {
      state = state.copyWith(isLoading: false, error: 'Web GSI error: $e');
      return false;
    }
  }

  /// Apple Sign In flow.
  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      if (identityToken == null) {
        state = state.copyWith(isLoading: false, error: 'Failed to get Apple identity token');
        return false;
      }

      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        if (fullName.isEmpty) fullName = null;
      }

      return _authenticateWithBackend(
        ApiEndpoints.authAppleMobile,
        {
          'identityToken': identityToken,
          'authorizationCode': authorizationCode,
          'email': credential.email,
          'fullName': fullName,
          'platform': 'mobile',
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Send token to backend and process response.
  Future<bool> _authenticateWithBackend(String endpoint, Map<String, dynamic> body) async {
    final result = await _apiClient.post<Map<String, dynamic>>(
      endpoint,
      data: body,
      fromJson: (d) => d as Map<String, dynamic>,
    );

    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error.message);
        return false;
      },
      (data) {
        if (data['success'] == true) {
          final token = data['sessionToken'] as String;
          final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
          _prefs.setString(_kSessionTokenKey, token);
          state = AuthState(user: user, sessionToken: token);
          return true;
        }
        state = state.copyWith(
          isLoading: false,
          error: data['error'] as String? ?? 'Authentication failed',
        );
        return false;
      },
    );
  }

  /// Logout.
  Future<void> logout() async {
    final token = state.sessionToken;
    if (token != null) {
      await _apiClient.post(
        ApiEndpoints.authLogout,
        data: {'sessionToken': token},
      );
    }
    _prefs.remove(_kSessionTokenKey);
    state = const AuthState();
  }

  /// Delete account.
  Future<bool> deleteAccount() async {
    final token = state.sessionToken;
    if (token == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.authDeleteUser,
      data: {'sessionToken': token},
      fromJson: (d) => d as Map<String, dynamic>,
    );

    return result.fold(
      (error) {
        state = state.copyWith(isLoading: false, error: error.message);
        return false;
      },
      (data) {
        if (data['success'] == true) {
          _prefs.remove(_kSessionTokenKey);
          state = const AuthState();
          return true;
        }
        state = state.copyWith(isLoading: false, error: 'Failed to delete account');
        return false;
      },
    );
  }

  /// Check if Apple Sign In is available on this platform.
  static bool get isAppleSignInAvailable {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }
}
