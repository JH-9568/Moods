// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moods/routes/app_router.dart';
import 'common/theme/app_theme.dart';

// ✅ providers + authController
import 'package:moods/providers.dart' show initialTokenProvider;
import 'package:moods/features/auth/controller/auth_controller.dart';

Future<void> _initServices() async {
  await Supabase.initialize(
    url: 'https://wrokgtvjuwlmrdqdcytc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indyb2tndHZqdXdsbXJkcWRjeXRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyNDMyNjksImV4cCI6MjA2NzgxOTI2OX0.Rdbu0Q9sdv4yAo2k37CRdTVi-raAizqCRcQ8FcKhTBs',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true, // 🔒 토큰 자동 갱신
      // detectSessionInUri: true, // 필요하면 주석 해제
    ),
  );

  KakaoSdk.init(nativeAppKey: '204b12b00149d9af0bd8814298314747');
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
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // ✅ Supabase 초기화 이후, 저장된 세션에서 초기 토큰 추출
        final initialToken =
            Supabase.instance.client.auth.currentSession?.accessToken;

        final GoRouter router = createAppRouter();

        // ✅ 초기 토큰 override + 앱 시작과 동시에 AuthController 구동
        return ProviderScope(
          overrides: [
            initialTokenProvider.overrideWithValue(initialToken),
          ],
          child: Consumer(
            builder: (_, ref, __) {
              // 이 줄로 AuthController가 생성되고 onAuthStateChange 구독 시작됨
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
        );
      },
    );
  }
}
