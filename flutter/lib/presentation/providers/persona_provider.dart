import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_helpers.dart';
import '../../data/models/persona_models.dart';
import 'core_providers.dart';

class PersonaNotifier extends StateNotifier<AsyncValue<PersonaSettings?>> {
  final ApiClient _api;

  PersonaNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> loadPersona() async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.get<dynamic>(ApiEndpoints.persona);
      result.fold(
        (error) => state = AsyncValue.error(error.message, StackTrace.current),
        (response) {
          final data = unwrapEnvelope(response);
          state = AsyncValue.data(
              PersonaSettings.fromJson(data as Map<String, dynamic>));
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<void> updateTone({
    required double emojiUsage,
    required double sentenceLength,
    required double colloquialism,
  }) async {
    try {
      final result = await _api.put<dynamic>(
        ApiEndpoints.personaTone,
        data: {
          'emoji_usage': emojiUsage,
          'sentence_length': sentenceLength,
          'colloquialism': colloquialism,
        },
      );
      result.fold(
        (error) {},
        (response) {
          final data = unwrapEnvelope(response);
          state = AsyncValue.data(
              PersonaSettings.fromJson(data as Map<String, dynamic>));
        },
      );
    } catch (_) {}
  }
}

final personaProvider =
    StateNotifierProvider<PersonaNotifier, AsyncValue<PersonaSettings?>>((ref) {
  return PersonaNotifier(ref.read(apiClientProvider));
});

class SandboxNotifier extends StateNotifier<AsyncValue<SandboxResult?>> {
  final ApiClient _api;

  SandboxNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> rewrite(String text) async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.post<dynamic>(
        ApiEndpoints.personaSandbox,
        data: {'text': text},
      );
      result.fold(
        (error) => state = AsyncValue.error(error.message, StackTrace.current),
        (response) {
          final data = unwrapEnvelope(response);
          state = AsyncValue.data(
              SandboxResult.fromJson(data as Map<String, dynamic>));
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final sandboxProvider =
    StateNotifierProvider<SandboxNotifier, AsyncValue<SandboxResult?>>((ref) {
  return SandboxNotifier(ref.read(apiClientProvider));
});
