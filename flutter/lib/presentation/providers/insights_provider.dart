import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_helpers.dart';
import '../../data/models/insights_models.dart';
import 'core_providers.dart';

class SkillsNotifier extends StateNotifier<AsyncValue<SkillScores?>> {
  final ApiClient _api;

  SkillsNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> loadSkills() async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.get<dynamic>(ApiEndpoints.insightsSkills);
      result.fold(
        (error) => state = AsyncValue.error(error.message, StackTrace.current),
        (response) {
          final data = unwrapEnvelope(response);
          state = AsyncValue.data(
              SkillScores.fromJson(data as Map<String, dynamic>));
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }
}

final skillsProvider =
    StateNotifierProvider<SkillsNotifier, AsyncValue<SkillScores?>>((ref) {
  return SkillsNotifier(ref.read(apiClientProvider));
});

class ReportsNotifier extends StateNotifier<AsyncValue<List<DateReport>>> {
  final ApiClient _api;

  ReportsNotifier(this._api) : super(const AsyncValue.data([]));

  Future<void> loadReports() async {
    state = const AsyncValue.loading();
    try {
      final result = await _api.get<dynamic>(ApiEndpoints.insightsReports);
      result.fold(
        (error) => state = AsyncValue.error(error.message, StackTrace.current),
        (response) {
          final data = unwrapEnvelope(response);
          final list = (data as List<dynamic>)
              .map((e) => DateReport.fromJson(e as Map<String, dynamic>))
              .toList();
          state = AsyncValue.data(list);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }
}

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<List<DateReport>>>((ref) {
  return ReportsNotifier(ref.read(apiClientProvider));
});

class VoiceCoachLogsNotifier
    extends StateNotifier<AsyncValue<List<VoiceCoachLog>>> {
  final ApiClient _api;

  VoiceCoachLogsNotifier(this._api) : super(const AsyncValue.data([]));

  Future<void> loadLogs() async {
    state = const AsyncValue.loading();
    try {
      final result =
          await _api.get<dynamic>(ApiEndpoints.insightsVoiceCoachLogs);
      result.fold(
        (error) =>
            state = AsyncValue.error(error.message, StackTrace.current),
        (response) {
          final data = unwrapEnvelope(response);
          final list = (data as List<dynamic>)
              .map(
                  (e) => VoiceCoachLog.fromJson(e as Map<String, dynamic>))
              .toList();
          state = AsyncValue.data(list);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }
}

final voiceCoachLogsProvider = StateNotifierProvider<VoiceCoachLogsNotifier,
    AsyncValue<List<VoiceCoachLog>>>((ref) {
  return VoiceCoachLogsNotifier(ref.read(apiClientProvider));
});
