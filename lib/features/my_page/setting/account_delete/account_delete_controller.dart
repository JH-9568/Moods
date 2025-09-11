// lib/features/my_page/setting/account_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/my_page/setting/account_delete/account_delete_service.dart';
import 'package:moods/providers.dart'; // accountServiceProvider 읽기용
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountState {
  final bool deleting;
  final String? lastMessage; // 서버가 준 메시지
  final String? error;

  const AccountState({this.deleting = false, this.lastMessage, this.error});

  AccountState copyWith({bool? deleting, String? lastMessage, String? error}) {
    return AccountState(
      deleting: deleting ?? this.deleting,
      lastMessage: lastMessage,
      error: error,
    );
  }
}

class AccountController extends StateNotifier<AccountState> {
  final AccountService service;
  AccountController({required this.service}) : super(const AccountState());

  /// 탈퇴
  Future<void> deleteUser() async {
    state = state.copyWith(deleting: true, error: null, lastMessage: null);
    try {
      final msg = await service.deleteMe();
      print('[AccountController] deleteUser OK: $msg');
      // (선택) 클라이언트 세션 정리
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      state = state.copyWith(deleting: false, lastMessage: msg, error: null);
    } catch (e) {
      print('[AccountController] deleteUser FAIL: $e');
      state = state.copyWith(deleting: false, error: e.toString());
    }
  }
}

/// Provider
final accountControllerProvider =
    StateNotifierProvider<AccountController, AccountState>((ref) {
      final svc = ref.read(accountServiceProvider);
      return AccountController(service: svc);
    });
