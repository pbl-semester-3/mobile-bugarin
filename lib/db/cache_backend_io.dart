import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_repository.dart';
import 'drift_cache_repository.dart';
import 'local_database.dart';

/// Implementasi native (Android/iOS/desktop): cache drift (SQLite).
CacheRepository createCacheRepository(Ref ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return DriftCacheRepository(db);
}
