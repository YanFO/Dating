import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

// SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// API Client — token getter is wired up after auth provider is available
final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiClient(
    tokenGetter: () => prefs.getString('auth_session_token'),
  );
});

// Voice Coach visibility (disabled — real-time voice feature is temporarily disabled)
final voiceCoachEnabledProvider = StateProvider<bool>((ref) => false);
