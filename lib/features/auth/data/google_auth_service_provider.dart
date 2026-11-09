import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../config/env.dart';
import 'google_auth_service.dart';

part 'google_auth_service_provider.g.dart';

@riverpod
GoogleAuthService googleAuthService(Ref ref) {
  return GoogleAuthServiceImpl(serverClientId: Env.googleClientId);
}
