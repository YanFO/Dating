import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_helpers.dart';
import '../../data/models/reply_models.dart';
import 'core_providers.dart';

class ReplyNotifier extends StateNotifier<AsyncValue<ReplyResult?>> {
  final ApiClient _api;

  ReplyNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> analyze({
    String? chatText,
    XFile? screenshot,
    String language = 'zh-TW',
    String relationshipStage = 'early',
    String userGender = 'male',
    String targetGender = 'female',
  }) async {
    state = const AsyncValue.loading();
    try {
      String? screenshotBase64;
      if (screenshot != null) {
        screenshotBase64 = base64Encode(await screenshot.readAsBytes());
      }

      final result = await _api.post<dynamic>(
        ApiEndpoints.replyAnalyze,
        data: {
          if (chatText != null && chatText.isNotEmpty) 'chat_text': chatText,
          if (screenshotBase64 != null) 'screenshot_base64': screenshotBase64,
          'language': language,
          'relationship_stage': relationshipStage,
          'user_gender': userGender,
          'target_gender': targetGender,
        },
      );

      result.fold(
        (error) => state = AsyncValue.error(error.message, StackTrace.current),
        (response) {
          final data = unwrapEnvelope(response);
          state =
              AsyncValue.data(ReplyResult.fromJson(data as Map<String, dynamic>));
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final replyProvider =
    StateNotifierProvider<ReplyNotifier, AsyncValue<ReplyResult?>>((ref) {
  return ReplyNotifier(ref.read(apiClientProvider));
});
