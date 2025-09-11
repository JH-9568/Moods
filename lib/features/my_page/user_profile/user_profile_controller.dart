// lib/features/my_page/profile/user_profile_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/my_page/user_profile/user_profile_service.dart';
import 'package:moods/providers.dart'; // userProfileServiceProvider 읽기용

class UserProfileState {
  final bool loading;
  final bool loadedOnce;
  final String? error;
  final UserProfile? profile;

  const UserProfileState({
    this.loading = false,
    this.loadedOnce = false,
    this.error,
    this.profile,
  });

  UserProfileState copyWith({
    bool? loading,
    bool? loadedOnce,
    String? error,
    UserProfile? profile,
  }) {
    return UserProfileState(
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: error,
      profile: profile ?? this.profile,
    );
  }
}

class UserProfileController extends StateNotifier<UserProfileState> {
  final UserProfileService service;
  UserProfileController({required this.service})
    : super(const UserProfileState());

  Future<void> loadIfNeeded() async {
    if (state.loading || state.loadedOnce) return;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final p = await service.fetchUserProfile();
      print(
        '[UserProfileController] fetched nickname=${p.nickname}, '
        'birthday=${p.birthday}, email=${p.email}, gender=${p.gender}',
      );

      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        profile: p,
        error: null,
      );
      print(
        '[UserProfileController] state applied. loadedOnce=${state.loadedOnce}',
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        error: e.toString(),
      );
    }
  }
}

/// 위젯에서 watch/read 할 프로바이더
final userProfileControllerProvider =
    StateNotifierProvider<UserProfileController, UserProfileState>((ref) {
      final svc = ref.read(userProfileServiceProvider);
      return UserProfileController(service: svc);
    });
