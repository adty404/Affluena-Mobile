import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/affluena_app.dart';
import 'app/provider_retry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DatePickerField and other date widgets format with the 'id_ID' locale,
  // which requires locale data to be initialized before use.
  await initializeDateFormatting('id_ID');
  runApp(const ProviderScope(retry: noProviderRetry, child: AffluenaApp()));
}
