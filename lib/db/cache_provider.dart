import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'cache_repository.dart';
import 'local_database.dart';

part 'cache_provider.g.dart';

@riverpod
LocalDatabase localDatabase(Ref ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
}

@riverpod
CacheRepository cacheRepository(Ref ref) {
  return DriftCacheRepository(ref.watch(localDatabaseProvider));
}
