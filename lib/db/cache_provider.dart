import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'cache_backend_stub.dart'
    if (dart.library.io) 'cache_backend_io.dart' as backend;
import 'cache_repository.dart';

part 'cache_provider.g.dart';

@riverpod
CacheRepository cacheRepository(Ref ref) => backend.createCacheRepository(ref);
