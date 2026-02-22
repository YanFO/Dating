import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

// SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// API Client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Voice Coach visibility
final voiceCoachEnabledProvider = StateProvider<bool>((ref) => true);
