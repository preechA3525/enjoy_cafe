import 'package:flutter/material.dart';

class CapsuleKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const CapsuleKey({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFE0EA),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF5B1840)),
      ),
    );
  }
}
