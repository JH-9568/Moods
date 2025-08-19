import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginCallbackHandler extends StatelessWidget {
  const LoginCallbackHandler({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() async {
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (session != null && user != null) {
        final metadata = user.userMetadata ?? {};

        final isNewKakaoUser = metadata['nickname'] == null ||
                               metadata['gender'] == null ||
                               metadata['birth'] == null;

        if (isNewKakaoUser) {
          context.push('/kakao');
        } else {
          context.go('/home');
        }
      } else {
        context.go('/start');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
