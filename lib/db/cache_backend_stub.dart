import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_repository.dart';
import 'noop_cache_repository.dart';

/// Fallback (web / platform tanpa `dart:io`): cache dinonaktifkan.
CacheRepository createCacheRepository(Ref ref) => NoopCacheRepository();
