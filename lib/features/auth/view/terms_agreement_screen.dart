import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/widgets/back_button.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool agreeAll = false;
  bool agreeService = false;
  bool agreePrivacy = false;

  void updateAgreeAll(bool? value) {
    setState(() {
      agreeAll = value ?? false;
      agreeService = agreeAll;
      agreePrivacy = agreeAll;
    });
  }

  void updateIndividual(bool? value, String type) {
    setState(() {
      if (type == 'service') agreeService = value ?? false;
      if (type == 'privacy') agreePrivacy = value ?? false;
      agreeAll = agreeService && agreePrivacy;
    });
  }

  bool get isAllChecked => agreeAll && agreeService && agreePrivacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('회원가입'),
        leading: const GlobalBackButton(),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              '회원가입을 위해\n약관 동의가 필요합니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildCheckboxTile(
              value: agreeAll,
              onChanged: updateAgreeAll,
              label: '전체 동의하기',
              bold: true,
            ),
            const Divider(height: 32),
            _buildCheckboxTile(
              value: agreeService,
              onChanged: (v) => updateIndividual(v, 'service'),
              label: '서비스 이용약관',
              tag: '필수',
            ),
            const SizedBox (height: 16,),
            _buildCheckboxTile(
              value: agreePrivacy,
              onChanged: (v) => updateIndividual(v, 'privacy'),
              label: '개인정보 수집 및 이용동의',
              tag: '필수',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isAllChecked
                    ? () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('terms_done', true); // ✅ 약관 동의 플래그 저장
        if (!mounted) return;
        context.go('/complete');                 // 원래 플로우: complete -> home
      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAllChecked
                      ? AppColors.checked
                      : AppColors.unchecked,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text('다음'),
              ),
            ),
            const SizedBox(height: 20,),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    String? tag,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => onChanged(!value),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: value ? AppColors.checked : AppColors.unchecked,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (tag != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.checked,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey)
      ],
    );
  }
}