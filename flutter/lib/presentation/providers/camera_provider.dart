import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final icebreakerImageProvider = StateProvider<XFile?>((ref) => null);

final coachImageProvider = StateProvider<XFile?>((ref) => null);
