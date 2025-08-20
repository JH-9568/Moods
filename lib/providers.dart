// lib/providers.dart
library app_providers;

export 'features/auth/controller/auth_controller.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/record/service/record_service.dart';

/// 1) 로그인 후 access_token을 넣어두는 전역 Provider
///    - 로그인 성공 시: ref.read(jwtProvider.notifier).state = accessToken;
final jwtProvider = StateProvider<String?>((ref) => null);

/// 2) RecordService 주입
///    - jwt가 바뀌면 자동으로 헤더 값도 반영됨 ("Bearer <token>" 형태로 전달)
final recordServiceProvider = Provider<RecordService>((ref) {
  final token = ref.watch(jwtProvider); // null 또는 실제 토큰
  String jwtHeader() => (token == null || token.isEmpty) ? '' : 'Bearer $token';
  return RecordService(jwtProvider: jwtHeader);
});
