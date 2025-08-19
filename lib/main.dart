// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moods/routes/app_router.dart';
import 'common/theme/app_theme.dart';

Future<void> _initServices() async {
  // Supabase 초기화 (절대 service_role 키 넣지 말 것)
  await Supabase.initialize(
    url: 'https://wrokgtvjuwlmrdqdcytc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indyb2tndHZqdXdsbXJkcWRjeXRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyNDMyNjksImV4cCI6MjA2NzgxOTI2OX0.Rdbu0Q9sdv4yAo2k37CRdTVi-raAizqCRcQ8FcKhTBs',

    // 🔑 OAuth는 PKCE로! (딥링크 host는 기본 'login-callback')
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // persistSession: true,
      // autoRefreshToken: true,
    ),
  );

  // Kakao SDK 초기화 (네이티브 앱 키)
  KakaoSdk.init(nativeAppKey: '204b12b00149d9af0bd8814298314747');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _Bootstrap()));
}

/// 초기화가 끝날 때까지 로딩 화면을 보여주고, 끝나면 실제 앱을 띄움.
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

        // Supabase 초기화 이후 라우터 생성 (세션/딥링크 반영)
        final GoRouter router = createAppRouter();

        return MaterialApp.router(
          routerConfig: router,
          theme: appTheme,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => child ?? const ColoredBox(color: Colors.white),
        );
      },
    );
  }
}
