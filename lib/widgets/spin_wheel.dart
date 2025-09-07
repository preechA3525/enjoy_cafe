import 'dart:math';
import 'package:flutter/material.dart';

class SpinWheel extends StatefulWidget {
  final Function(String) onResult;
  const SpinWheel({super.key, required this.onResult});

  @override
  State<SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<SpinWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();

  // ✅ รายการเมนูที่ใช้ในวงล้อ
  final List<String> items = [
    'M150 ปั่นปีโป้',
    'นมเปรี้ยวปั่นปีโป้',
    'แตงโมปั่น',
    'สตอเบอร์รี่ปั่น',
    'โอริโอ้นมสดปั่น',
    'โค๊กแก้วโอ่ง',
    'กาแฟ',
    'โอเลี้ยง',
    'นมสดบราวน์ซูก้า',
    'ชานมบราวน์ซูก้าร์',
    'ชาเขียวบราวน์ซูก้าร์',
    'เผือกนมสดบราวน์ซูก้าร์',
    'นมชมภูบราวน์ซูก้าร์',
    'โกโก้',
    'โอวัลติน',
    'ไมโล',
    'สัปปะรด',
    'ลิ้นขี่',
    'พันช์',
    'องุ่นเคียวโฮ',
    'น้ำผึ้งมะนาว',
    'เก็กฮวย',
    'ชาพีช',
    'นมชมภู',
    'นมสดสตอเบอร์รี่',
    'นมสดเผือก',
    'ชานมใต้หวัน',
    'ชามะนาว',
    'ชาไทยนม',
    'ชาเขียวนม',
    'ชานมคาราเมล',
    'แอปเปิ้ลโซดา',
    'พีชโซดา',
    'สตอเบอร์รี่โซดา',
    'พันช์โซดา',
    'แดงโซดา',
    'เมล่อนโซดา',
    'มะนาวโซดา',
    'ลิ้นจี่โซดา',
    'แดงมะนาวโซดา',
    'น้ำผึ้งมะนาวโซดา',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  /// ฟังก์ชันเริ่มหมุนวงล้อ
  void _spin() {
    final randomIndex = _random.nextInt(items.length);
    final angle = (2 * pi * randomIndex / items.length) + (10 * pi);

    _animation = Tween<double>(begin: 0, end: angle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.reset();
    _controller.forward().whenComplete(() {
      widget.onResult(items[randomIndex]);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// วาดวงล้อแบบง่าย (แบ่งสี)
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value,
                child: CustomPaint(
                  painter: _WheelPainter(items),
                  child: Container(),
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: _spin,
          child: const Text("หมุนวงล้อ"),
        ),
      ],
    );
  }
}

/// Custom Painter สำหรับวาดวงล้อ
class _WheelPainter extends CustomPainter {
  final List<String> items;
  _WheelPainter(this.items);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final sweepAngle = 2 * pi / items.length;

    for (int i = 0; i < items.length; i++) {
      paint.color = i.isEven ? Colors.orange.shade300 : Colors.yellow.shade300;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
