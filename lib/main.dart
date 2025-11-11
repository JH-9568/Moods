import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:moods/routes/app_router.dart';
import 'common/theme/app_theme.dart';
import 'package:moods/features/my_page/user_profile/user_profile_controller.dart'; // userProfileControllerProvider 임포트 추가
import 'package:moods/providers.dart';
import 'package:moods/features/auth/controller/auth_controller.dart';

final routerPingProvider = Provider((ref) => routerPing);

Future<void> _initServices() async {
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Supabase credentials are missing. Set SUPABASE_URL and SUPABASE_ANON_KEY in .env or via --dart-define.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  final kakaoKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ??
      const String.fromEnvironment('KAKAO_NATIVE_APP_KEY', defaultValue: '');
  if (kakaoKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoKey);
  } else {
    debugPrint(
      '⚠️ Kakao native app key missing; Kakao login will be disabled.',
    );
  }
}

// 로컬 유틸: JWT 만료 체크 (leeway 30s)
bool _isJwtExpired(String token, {int leewaySec = 30}) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    var b64 = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (b64.length % 4 != 0) {
      b64 += '=';
    }
    final payload = jsonDecode(utf8.decode(base64Url.decode(b64)));
    final exp = payload['exp'];
    if (exp is! num) return true;
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return nowSec >= (exp.toInt() - leewaySec);
  } catch (_) {
    return true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('ℹ️ .env not found: $e');
  }
  runApp(const ProviderScope(child: _Bootstrap()));
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _loading();
        }

        // Supabase 초기화 완료 후 SharedPreferences 로드
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefsSnap) {
            if (!prefsSnap.hasData) return _loading();

            final prefs = prefsSnap.data!;
            final supaToken =
                Supabase.instance.client.auth.currentSession?.accessToken;
            final customToken = prefs.getString('access_token');

            // ▷ 유효한 토큰만 선택 (Supabase > custom 폴백)
            String? pickValid(String? t) =>
                (t != null && t.isNotEmpty && !_isJwtExpired(t)) ? t : null;

            final initialToken = pickValid(supaToken) ?? pickValid(customToken);

            final router = createAppRouter();

            print(
              '🚀 App bootstrap initial token: ${initialToken == null ? "(none)" : initialToken.substring(0, 12) + "•••"}',
            );

            return ProviderScope(
              overrides: [
                initialTokenProvider.overrideWithValue(initialToken),
                authTokenProvider.overrideWith((ref) => initialToken),
              ],
              child: _AuthSyncer(
                child: Consumer(
                  builder: (_, ref, __) {
                    // 기존 authController 구독 유지
                    ref.watch(authControllerProvider);
                    return MaterialApp.router(
                      routerConfig: router,
                      theme: appTheme,
                      debugShowCheckedModeBanner: false,
                      builder: (context, child) =>
                          child ?? const ColoredBox(color: Colors.white),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _loading() => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    ),
  );
}

/// Supabase onAuthStateChange → authTokenProvider & SharedPreferences 동기화
class _AuthSyncer extends StatefulWidget {
  final Widget child;
  const _AuthSyncer({required this.child});

  @override
  State<_AuthSyncer> createState() => _AuthSyncerState();
}

class _AuthSyncerState extends State<_AuthSyncer> {
  @override
void initState() {
  super.initState();

  Supabase.instance.client.auth.onAuthStateChange.listen((auth) async {
    final event = auth.event;
    final session = auth.session;

    // 1) 초기 null 세션은 무시 (지우지 말기)
    if (event == AuthChangeEvent.initialSession) {
      print('⏭️ Auth state: initialSession(with ${session == null ? "null" : "session"}) — ignore');
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    // 2) Supabase 경로 로그인(카카오 등)만 자동 세팅
    if (event == AuthChangeEvent.signedIn && (session?.accessToken?.isNotEmpty ?? false)) {
      final t = session!.accessToken!;
      container.read(authTokenProvider.notifier).state = t;
      await prefs.setString('access_token', t);
      print('🔄 AuthSyncer: signedIn → token set ${t.substring(0, 12)}•••');
      // 새 로그인 시 프로필 정보를 다시 불러오도록 무효화
      container.invalidate(userProfileControllerProvider);
      routerPing.ping(); // 로그인 반영
      return;
    }

    // 3) Supabase 로그아웃만 클리어
    if (event == AuthChangeEvent.signedOut) {
      container.read(authTokenProvider.notifier).state = null;
      // 로그아웃 시 캐시된 프로필도 초기화
      container.invalidate(userProfileControllerProvider);
      await prefs.remove('access_token');
      print('🔄 AuthSyncer: signedOut → token cleared');
      routerPing.ping();
      return;
    }

    print('ℹ️ AuthSyncer: event=$event ignored');
  });
}

  @override
  Widget build(BuildContext context) => widget.child;
}
