import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  final bool isExpanded;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grayNormal),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: isExpanded,
          hint: Text(
            hint,
            style: const TextStyle(
              color: AppColors.grayText,
              fontSize: 14,
            ),
          ),
          icon: const Icon(Icons.expand_more, color: AppColors.grayText),
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 14,
          ),
          dropdownColor: AppColors.white,
        ),
      ),
    );
  }
}
