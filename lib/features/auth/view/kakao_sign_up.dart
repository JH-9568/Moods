import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';

class AdditionalInfoScreen extends StatefulWidget {
  const AdditionalInfoScreen({super.key});

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> { //화면의 상태를 담당하는 class
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  String selectedGender = '';

  @override
  void initState() {
    super.initState();
    birthController.addListener(_formatBirthday);
  }

  void _formatBirthday() {
    String digits = birthController.text.replaceAll('.', '');
    String formatted = '';

    for (int i = 0; i < digits.length && i < 8; i++) {
      formatted += digits[i];
      if ((i == 3 || i == 5) && i != digits.length - 1) {
        formatted += '.';
      }
    }

    if (formatted != birthController.text) {
      birthController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    setState(() {}); // 생년월일 변경 시 버튼 상태 갱신
  }

  @override
  Widget build(BuildContext context) {
    final isNextEnabled = nicknameController.text.isNotEmpty &&
        birthController.text.length == 10 &&
        selectedGender.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '추가 정보를\n입력해주세요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            const Text('닉네임',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                fillColor: Colors.white,
                filled: true,
                hintText: '닉네임',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    width: 1,
                    color: AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    width: 1,
                    color: AppColors.border, // 포커스 시 보라색 테두리
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),
            const Text('생년월일',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: birthController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                fillColor: Colors.white,
                filled: true,
                hintText: 'YYYY.MM.DD',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    width: 1,
                    color: AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    width: 1,
                    color: AppColors.border, // 포커스 시 보라색 테두리
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text('성별',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGender = '남성';
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedGender == '남성' ? AppColors.main : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('남성', style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        )),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: const Color(0xFFE9E8F1),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGender = '여성';
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedGender == '여성' ? AppColors.main : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('여성', style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isNextEnabled
                    ? () {
                  context.go('/terms');
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNextEnabled
                      ? AppColors.main
                      : AppColors.unchecked,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.unchecked,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    birthController.removeListener(_formatBirthday);
    birthController.dispose();
    nicknameController.dispose();
    super.dispose();
  }
}