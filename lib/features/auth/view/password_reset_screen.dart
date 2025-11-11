// features/auth/view/password_reset_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/widgets/back_button.dart';
import 'package:moods/features/auth/controller/auth_controller.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  // 이메일 파트
  final TextEditingController emailIdController = TextEditingController();
  final TextEditingController emailCustomDomainController = TextEditingController();
  String selectedDomain = '직접입력';

  // 팝업 위치용
  final GlobalKey _domainKey = GlobalKey();

  @override
  void dispose() {
    emailIdController.dispose();
    emailCustomDomainController.dispose();
    super.dispose();
  }

  String _fullEmail() {
    final id = emailIdController.text.trim();
    final domain = selectedDomain == '직접입력'
        ? emailCustomDomainController.text.trim()
        : selectedDomain.trim();
    if (id.isEmpty || domain.isEmpty) return '';
    return '$id@$domain';
  }

  bool get _canSend {
    final email = _fullEmail();
    final ok = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
    return ok;
  }

  // 회원가입 화면에서 쓰던 스타일
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border, width: 2),
      ),
    );
  }

  // 공통 도메인 드롭다운 위젯 (회원가입과 동일)
  Widget _buildEmailDomainSelector() {
    final fullDomainList = ['직접입력', 'naver.com', 'gmail.com', 'daum.net', 'nate.com'];
    final filteredDomainList = fullDomainList.where((d) => d != selectedDomain).toList();

    return GestureDetector(
      key: _domainKey,
      onTap: () async {
        final renderBox = _domainKey.currentContext?.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        final selected = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx, offset.dy + size.height, offset.dx + size.width, offset.dy + size.height),
          constraints: BoxConstraints(minWidth: size.width, maxWidth: size.width),
          color: AppColors.gray1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.border),
          ),
          elevation: 0,
          items: filteredDomainList.map((domain) {
            return PopupMenuItem<String>(
              value: domain,
              padding: EdgeInsets.zero,
              child: Container(
                height: 40,
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  domain,
                  style: const TextStyle(fontSize: 14, color: AppColors.grayText, fontWeight: FontWeight.w400),
                ),
              ),
            );
          }).toList(),
        );

        if (selected != null) {
          setState(() {
            selectedDomain = selected;
            if (selected == '직접입력') {
              emailCustomDomainController.clear();
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: selectedDomain == '직접입력'
                  ? TextField(
                      controller: emailCustomDomainController,
                      decoration: const InputDecoration.collapsed(hintText: '직접입력'),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (_) => setState(() {}),
                    )
                  : Text(selectedDomain, style: const TextStyle(fontSize: 14)),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.grayText),
          ],
        ),
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    final email = _fullEmail();
    if (!_canSend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일을 입력해 주세요.')),
      );
      return;
    }

    final controller = ref.read(authControllerProvider.notifier);
    try {
      await controller.sendPasswordResetEmail(email);

      // 시안 스타일 안내 다이얼로그
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFFF2EEFA),
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이메일을 확인해주세요.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '이메일에서 비밀번호 재설정이 가능해요.',
                  style: TextStyle(fontSize: 14, color: AppColors.grayText),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.main,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/start'); // 바로 로그인 화면으로
                    },
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메일 전송 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 버튼 올리기: Spacer 제거, 고정 간격만 사용
    final buttonEnabled = _canSend;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('비밀번호 재설정', style: TextStyle(fontSize: 20, color: AppColors.black)),
        // 공통 뒤로가기 버튼 사용
        leading: const GlobalBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시안처럼 조금 더 크게
            const Text(
              '이메일로 비밀번호\n재설정이 가능해요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),

            const Text('이메일'),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: emailIdController,
                    decoration: _inputDecoration('이메일'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('@')),
                Expanded(flex: 2, child: _buildEmailDomainSelector()),
              ],
            ),
            // 버튼을 조금 더 위로 배치
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: buttonEnabled ? _sendResetEmail : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonEnabled ? AppColors.main : AppColors.unchecked,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('이메일 보내기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
