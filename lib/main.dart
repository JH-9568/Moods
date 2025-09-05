import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moods/routes/app_router.dart';
import 'common/theme/app_theme.dart';
import 'package:moods/providers.dart';
import 'package:moods/features/auth/controller/auth_controller.dart';

final routerPingProvider = Provider((ref) => routerPing);

Future<void> _initServices() async {
  await Supabase.initialize(
    url: 'https://wrokgtvjuwlmrdqdcytc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indyb2tndHZqdXdsbXJkcWRjeXRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyNDMyNjksImV4cCI6MjA2NzgxOTI2OX0.Rdbu0Q9sdv4yAo2k37CRdTVi-raAizqCRcQ8FcKhTBs', // 그대로
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  KakaoSdk.init(nativeAppKey: '204b12b00149d9af0bd8814298314747');
}

// === 로컬 유틸: JWT 만료 체크 (leeway 30s) ===
bool _isJwtExpired(String token, {int leewaySec = 30}) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    var b64 = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    while (b64.length % 4 != 0) { b64 += '='; }
    final payload = jsonDecode(utf8.decode(base64Url.decode(b64)));
    final exp = payload['exp'];
    if (exp is! num) return true;
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return nowSec >= (exp.toInt() - leewaySec);
  } catch (_) {
    return true;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

        //  Supabase 초기화 완료 후 SharedPreferences 로드
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefsSnap) {
            if (!prefsSnap.hasData) return _loading();

            final prefs = prefsSnap.data!;
            final supaToken = Supabase.instance.client.auth.currentSession?.accessToken;
            final customToken = prefs.getString('access_token');

            // ▷ 유효한 토큰만 선택 (Supabase > custom 폴백)
            String? pickValid(String? t) =>
                (t != null && t.isNotEmpty && !_isJwtExpired(t)) ? t : null;

            final initialToken = pickValid(supaToken) ?? pickValid(customToken);

            final router = createAppRouter();

            print('🚀 App bootstrap initial token: ${initialToken == null ? "(none)" : initialToken.substring(0, 12) + "•••"}');

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
      routerPing.ping(); // 로그인 반영
      return;
    }

    // 3) Supabase 로그아웃만 클리어
    if (event == AuthChangeEvent.signedOut) {
      container.read(authTokenProvider.notifier).state = null;
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

