import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local, offline-first storage. Hive boxes back small key-value data
  // (settings, auth session mirror, cache); Drift (added in the Inventory /
  // POS phases) backs relational offline data that needs querying/joins.
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveSettingsBox);
  await Hive.openBox(AppConstants.hiveCacheBox);

  runApp(const ProviderScope(child: LycanOSApp()));
}
