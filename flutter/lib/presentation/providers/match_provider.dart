import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_helpers.dart';
import '../../data/models/match_models.dart';
import 'core_providers.dart';

class MatchNotifier extends StateNotifier<AsyncValue<List<MatchRecord>>> {
  final ApiClient _api;

  MatchNotifier(this._api) : super(const AsyncValue.data([]));

  Future<void> loadMatches() async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.get<dynamic>(ApiEndpoints.matches);
      result.fold(
        (error) => state = AsyncValue.error(error.message, StackTrace.current),
        (response) {
          final data = unwrapEnvelope(response);
          final list = (data as List<dynamic>)
              .map((e) => MatchRecord.fromJson(e as Map<String, dynamic>))
              .toList();
          state = AsyncValue.data(list);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<void> createMatch(String name, {String? contextTag}) async {
    try {
      final result = await _api.post<dynamic>(
        ApiEndpoints.matches,
        data: {
          'name': name,
          if (contextTag != null) 'context_tag': contextTag,
        },
      );
      result.fold(
        (error) {},
        (response) {
          final data = unwrapEnvelope(response);
          final match =
              MatchRecord.fromJson(data as Map<String, dynamic>);
          final current = state.valueOrNull ?? [];
          state = AsyncValue.data([...current, match]);
        },
      );
    } catch (_) {}
  }

  Future<void> deleteMatch(String matchId) async {
    try {
      final result =
          await _api.delete<dynamic>(ApiEndpoints.matchById(matchId));
      result.fold(
        (error) {},
        (_) {
          final current = state.valueOrNull ?? [];
          state = AsyncValue.data(
              current.where((m) => m.matchId != matchId).toList());
        },
      );
    } catch (_) {}
  }
}

final matchProvider =
    StateNotifierProvider<MatchNotifier, AsyncValue<List<MatchRecord>>>((ref) {
  return MatchNotifier(ref.read(apiClientProvider));
});
