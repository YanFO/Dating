import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_helpers.dart';
import '../../data/models/icebreaker_models.dart';
import 'core_providers.dart';

class IcebreakerNotifier extends StateNotifier<AsyncValue<IcebreakerResult?>> {
  final ApiClient _api;

  IcebreakerNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> analyze({
    String? description,
    XFile? image,
    String language = 'zh-TW',
  }) async {
    state = const AsyncValue.loading();
    try {
      String? imageBase64;
      if (image != null) {
        imageBase64 = base64Encode(await image.readAsBytes());
      }

      final result = await _api.post<dynamic>(
        ApiEndpoints.icebreakerAnalyze,
        data: {
          if (description != null && description.isNotEmpty)
            'scene_description': description,
          if (imageBase64 != null) 'image_base64': imageBase64,
          'language': language,
        },
      );

      result.fold(
        (error) => state = AsyncValue.error(error.message, StackTrace.current),
        (response) {
          final data = unwrapEnvelope(response);
          state =
              AsyncValue.data(IcebreakerResult.fromJson(data as Map<String, dynamic>));
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final icebreakerProvider =
    StateNotifierProvider<IcebreakerNotifier, AsyncValue<IcebreakerResult?>>(
        (ref) {
  return IcebreakerNotifier(ref.read(apiClientProvider));
});
