import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n.dart';

extension TrExtension on WidgetRef {
  String tr(String key) => watch(stringsProvider)[key] ?? key;
}
