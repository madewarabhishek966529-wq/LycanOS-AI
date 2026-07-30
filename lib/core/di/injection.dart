import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../network/dio_client.dart';

/// Central dependency-injection providers.
///
/// Every core singleton (secure storage, the Dio client, Hive boxes, later
/// the Drift database and repositories) is exposed as a Riverpod provider
/// here so features consume them via `ref.watch` / `ref.read` instead of
/// constructing them ad hoc. This keeps the composition root in one file
/// and makes every dependency swappable in tests via `ProviderScope`
/// overrides.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(secureStorage: secureStorage);
});

/// Hive boxes are opened once during app bootstrap (see main.dart) and
/// exposed here for repositories to read/write without re-opening.
final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.hiveSettingsBox);
});

final cacheBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.hiveCacheBox);
});
