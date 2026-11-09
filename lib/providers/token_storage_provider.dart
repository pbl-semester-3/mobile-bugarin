import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());