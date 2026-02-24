import 'dart:typed_data';

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

  /// Parse matches array from API response and update state.
  List<MatchRecord> _parseMatchesResponse(dynamic response) {
    final data = unwrapEnvelope(response);
    final matchesList = data['matches'] as List<dynamic>;
    final matches = matchesList
        .map((item) => MatchRecord.fromJson(
            (item['match'] as Map<String, dynamic>)))
        .toList();
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...matches, ...current]);
    return matches;
  }

  /// Import chat text or single image, LLM analyzes and creates match(es).
  /// Returns the new MatchRecord on success, null on failure.
  Future<MatchRecord?> importChat({String? chatText, Uint8List? imageBytes, String? imageFilename}) async {
    try {
      if (imageBytes != null) {
        final result = await _api.uploadFile<dynamic>(
          ApiEndpoints.matchImportChat,
          bytes: imageBytes,
          filename: imageFilename ?? 'image.jpg',
          fieldName: 'image',
          extraFields: chatText != null ? {'chat_text': chatText} : null,
        );
        return result.fold(
          (error) => null,
          (response) {
            final matches = _parseMatchesResponse(response);
            return matches.isNotEmpty ? matches.first : null;
          },
        );
      } else {
        final result = await _api.post<dynamic>(
          ApiEndpoints.matchImportChat,
          data: {'chat_text': chatText},
        );
        return result.fold(
          (error) => null,
          (response) {
            final matches = _parseMatchesResponse(response);
            return matches.isNotEmpty ? matches.first : null;
          },
        );
      }
    } catch (_) {
      return null;
    }
  }

  /// Import multiple images at once. LLM identifies different people
  /// by avatar and chat room name, creates one match per person.
  /// Returns list of new MatchRecords on success, null on failure.
  Future<List<MatchRecord>?> importChatMulti({
    required List<Uint8List> imageBytesList,
    required List<String> filenames,
    String? chatText,
  }) async {
    try {
      final result = await _api.uploadFiles<dynamic>(
        ApiEndpoints.matchImportChat,
        bytesList: imageBytesList,
        filenames: filenames,
        fieldName: 'images',
        extraFields: chatText != null ? {'chat_text': chatText} : null,
      );
      return result.fold(
        (error) => null,
        (response) => _parseMatchesResponse(response),
      );
    } catch (_) {
      return null;
    }
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

// ─── Memory Provider ──────────────────────────────

class MemoryNotifier extends StateNotifier<AsyncValue<MemoryProfile?>> {
  final ApiClient _api;

  MemoryNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> loadMemory(String matchId) async {
    state = const AsyncValue.loading();
    try {
      final result =
          await _api.get<dynamic>(ApiEndpoints.matchMemory(matchId));
      result.fold(
        (error) => state = AsyncValue.error(error.message, StackTrace.current),
        (response) {
          final data = unwrapEnvelope(response);
          state = AsyncValue.data(
              MemoryProfile.fromJson(data as Map<String, dynamic>));
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<void> upsertMemory(
      String matchId, Map<String, dynamic> updates) async {
    try {
      final result = await _api.put<dynamic>(
        ApiEndpoints.matchMemory(matchId),
        data: updates,
      );
      result.fold(
        (error) {},
        (response) {
          final data = unwrapEnvelope(response);
          state = AsyncValue.data(
              MemoryProfile.fromJson(data as Map<String, dynamic>));
        },
      );
    } catch (_) {}
  }

  Future<void> deleteMemory(String matchId) async {
    try {
      final result =
          await _api.delete<dynamic>(ApiEndpoints.matchMemory(matchId));
      result.fold(
        (error) {},
        (_) => state = const AsyncValue.data(null),
      );
    } catch (_) {}
  }

  void clear() => state = const AsyncValue.data(null);
}

final memoryProvider =
    StateNotifierProvider<MemoryNotifier, AsyncValue<MemoryProfile?>>((ref) {
  return MemoryNotifier(ref.read(apiClientProvider));
});
