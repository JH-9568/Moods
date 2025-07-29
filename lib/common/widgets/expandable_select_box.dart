import 'package:flutter/material.dart';

class ExpandableSelectBox extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;

  const ExpandableSelectBox({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ExpandableSelectBox> createState() => _ExpandableSelectBoxState();
}

class _ExpandableSelectBoxState extends State<ExpandableSelectBox> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.value ?? widget.label,
                    style: TextStyle(
                      color: widget.value == null
                          ? Colors.grey
                          : Colors.black,
                    )),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: widget.items.map((item) {
                return ListTile(
                  title: Text(item),
                  onTap: () {
                    widget.onChanged(item);
                    setState(() {
                      isExpanded = false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

/* 
ExpandableSelectBox(
  label: '직접입력',
  items: ['카페', '스터디룸', '도서관'],
  value: selectedValue,
  onChanged: (val) {
    setState(() {
      selectedValue = val;
    });
  },
),
*/