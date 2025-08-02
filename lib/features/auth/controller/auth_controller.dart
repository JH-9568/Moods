// auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/auth/service/auth_service.dart';

final authTokenProvider = StateProvider<String?>((ref) => null);

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref, AuthService());
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final AuthService _authService;

  AuthController(this.ref, this._authService)
      : super(const AsyncValue.data(null));

  // ✅ 로그인
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final token = await _authService.login(email, password);
      ref.read(authTokenProvider.notifier).state = token;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ✅ 최초 인증번호 요청 → UUID 반환
  Future<String?> requestInitialVerification({
    required String email,
    required String password,
    required String nickname,
    required String birth,
    required String gender,
  }) async {
    state = const AsyncValue.loading();
    try {
      final uuid = await _authService.requestInitialVerification(
        email: email,
        password: password,
        nickname: nickname,
        birth: birth,
        gender: gender,
      );
      state = const AsyncValue.data(null);
      return uuid;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  // ✅ 이메일 인증번호 재전송
  Future<void> sendVerificationCode(String email) async {
    try {
      await _authService.sendVerificationCode(email);
    } catch (e) {
      rethrow;
    }
  }

  // ✅ 이메일 인증 여부 확인 (UUID 사용)
  Future<bool> checkEmailVerified(String uuid) async {
    try {
      return await _authService.checkEmailVerified(uuid);
    } catch (e) {
      rethrow;
    }
  }

  // ✅ 최종 회원가입 확정
  Future<void> confirmSignUp({
    required String email,
    required String password,
    required String nickname,
    required String birth,
    required String gender,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.confirmSignUp(
        email: email,
        password: password,
        nickname: nickname,
        birth: birth,
        gender: gender,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}