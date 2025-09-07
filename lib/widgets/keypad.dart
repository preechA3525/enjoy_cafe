import 'package:flutter/material.dart';
import 'capsule_key.dart';

class Keypad extends StatelessWidget {
  final void Function(String) onNumber;
  final VoidCallback onBackspace, onClear;
  const Keypad({super.key, required this.onNumber, required this.onBackspace, required this.onClear});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['ย้อนกลับ', '0', 'ลบ'],
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
      ),
      child: Table(
        children: rows.map((row) => TableRow(
          children: row.map((k) => Padding(
            padding: const EdgeInsets.all(4),
            child: CapsuleKey(
              label: k,
              onTap: () {
                if (k == 'ย้อนกลับ') onBackspace();
                else if (k == 'ลบ') onClear();
                else onNumber(k.trim()); // <-- trim space ป้องกันปัญหา
              },
            ),
          )).toList(),
        )).toList(),
      ),
    );
  }
}
