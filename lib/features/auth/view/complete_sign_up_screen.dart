import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moods/common/constants/colors_j.dart';
// textSB 스타일 사용을 위해 필요
import 'package:moods/common/constants/text_styles.dart';

class SignUpCompleteScreen extends StatelessWidget {
  const SignUpCompleteScreen({super.key});

  Future<void> _goHome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_done', true);
    if (!context.mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경을 메인4 컬러로 고정
      backgroundColor: AppColorsJ.main4,
      body: Stack(
        children: [
          // 하단 그라데이션 오버레이 (위 투명 → 아래 살짝 어두움)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.16),
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 콘텐츠
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // 중앙 무스 아이콘
                Image.asset(
                  // pubspec.yaml에 등록된 정식 경로
                  'assets/fonts/icons/moodsicon.png',
                  width: 260,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),

                // 타이틀
                const Text(
                  '회원가입이 완료되었습니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // 서브 카피
                const Text(
                  'Moods를 시작해 보세요 !',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),

                const Spacer(),
                // 확인 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _goHome(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        '확인',
                        // 요청된 강조 스타일 적용
                        style: AppTextStyles.textSbEmphasis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
