
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/database_service.dart';

/// ===== PrettySpinner: วงแหวนไล่เฉด + จุดวิ่งรอบ ๆ (ไม่มี dependency เพิ่ม) =====
class PrettySpinner extends StatefulWidget {
  final double size;
  final double ringThickness;
  const PrettySpinner({super.key, this.size = 110, this.ringThickness = 10});

  @override
  State<PrettySpinner> createState() => _PrettySpinnerState();
}

class _PrettySpinnerState extends State<PrettySpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final thickness = widget.ringThickness;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final angle = _c.value * 2 * pi;
          return Stack(
            alignment: Alignment.center,
            children: [
              // วงแหวนไล่เฉดหมุน
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        spreadRadius: 0,
                        color: Color(0x22E91E63),
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (rect) => const SweepGradient(
                      startAngle: 0.0,
                      endAngle: 2 * pi,
                      stops: [0.0, 0.3, 0.6, 1.0],
                      colors: [
                        Color(0xFFE91E63), // ชมพู
                        Color(0xFF2196F3), // น้ำเงิน
                        Color(0xFFFF9800), // ส้ม
                        Color(0xFFE91E63), // กลับมาที่ชมพู
                      ],
                    ).createShader(rect),
                    blendMode: BlendMode.srcATop,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: thickness,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // วงในสีขาวให้ดูเป็นแหวน
              Container(
                width: size - thickness * 2,
                height: size - thickness * 2,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: Offset(0, 6),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
              ),
              // จุดวิ่งรอบ (3 จุด phase ต่างกัน)
              _dot(size, size / 2 - 6, angle),
              _dot(size, size / 2 - 6, angle + 2.0944),
              _dot(size, size / 2 - 6, angle + 4.1888),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(double size, double r, double a) {
    final cx = size / 2 + r * cos(a);
    final cy = size / 2 + r * sin(a);
    return Positioned(
      left: cx - 6,
      top: cy - 6,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE91E63),
        ),
      ),
    );
  }
}

/// ===== WaitingPopup (เหมือนเดิม: ปิดเองหลังอนุมัติ+พูดจบ) =====
class WaitingPopup extends StatefulWidget {
  final String requestId, phone;
  final DatabaseService db;
  final FlutterTts tts;
  const WaitingPopup({
    super.key,
    required this.requestId,
    required this.phone,
    required this.db,
    required this.tts,
  });
  @override
  State<WaitingPopup> createState() => _WaitingPopupState();
}

class _WaitingPopupState extends State<WaitingPopup> {
  StreamSubscription? _sub;
  String _message = 'รอแม่ค้าให้แต้มแป๊ปนึงนะคะ';
  bool _canClose = false;

  static const cocoa = Color(0xFF4E342E);

  @override
  void initState() {
    super.initState();
    widget.tts.awaitSpeakCompletion(true);
    widget.tts.speak(_message);
    _sub = widget.db.requestRefById(widget.requestId).onValue.listen((e) async {
      if (!mounted || !e.snapshot.exists) return;
      final m = (e.snapshot.value ?? {}) as Map;
      final status = '${m['status'] ?? 'pending'}';
      if (status == 'approved') {
        final pts = await widget.db.getPoints(widget.phone);
        setState(() {
          _message = 'ขอบคุณที่มาอุดหนุน ตอนนี้คุณมี $pts แต้มแล้ว';
          _canClose = true;
        });
        await widget.tts.speak(_message);
        if (!mounted) return;
        Navigator.pop(context, 'approved');
      } else if (status == 'rejected') {
        setState(() {
          _message = 'คำขอถูกปฏิเสธแล้ว';
          _canClose = true;
        });
        await widget.tts.speak(_message);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('สถานะการสะสมแต้ม',
          style: TextStyle(color: Color(0xFF4E342E))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'รอแม่ค้าให้แต้มแป๊ปนึงนะคะ',
            style: TextStyle(fontSize: 18, color: Color(0xFF4E342E)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          PrettySpinner(size: 110, ringThickness: 10),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        ElevatedButton(
          onPressed: null, // ปิดได้เมื่ออนุมัติแล้ว (จะ pop อัตโนมัติ)
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape: const StadiumBorder(),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          child: const Text('ปิด'),
        ),
      ],
    );
  }
}

/// ===== RedeemPopup (พูดแต้ม -> รอ 4 วินาที -> ปิดเอง และส่งผลลัพธ์ให้หน้าแม่) =====
class RedeemPopup extends StatefulWidget {
  final String phone;
  final int points, redeemable;
  final DatabaseService db;
  final FlutterTts tts;
  const RedeemPopup({
    super.key,
    required this.phone,
    required this.points,
    required this.redeemable,
    required this.db,
    required this.tts,
  });
  @override
  State<RedeemPopup> createState() => _RedeemPopupState();
}

class _RedeemPopupState extends State<RedeemPopup> {
  StreamSubscription? _sub;
  String _phase = 'select';
  String _message = '';

  static const cocoa = Color(0xFF4E342E);
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _message = 'คุณมี ${widget.points} แต้ม แลกได้ ${widget.redeemable} แก้ว';
    widget.tts.awaitSpeakCompletion(true);
    // ให้แน่ใจว่า UI โชว์ก่อน แล้วค่อยพูดแต้ม -> จากนั้นหน่วง 4 วิ แล้วปิดเอง
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.tts.speak('ตอนนี้คุณมี ${widget.points} แต้ม แลกได้ ${widget.redeemable} แก้ว');
      if (!mounted) return;
      _autoTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) Navigator.pop(context, 'redeem_info_shown');
      });
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _sendRedeem(int count) async {
    setState(() {
      _phase = 'waiting';
      _message = 'กำลังขอแลกรางวัล...';
    });
    await widget.db.sendRedeemRequest(phone: widget.phone, count: count);
    await widget.tts.speak('กำลังขอแลกรางวัล');
    _sub = widget.db.redeemRefByPhone(widget.phone).onValue.listen((e) async {
      if (!mounted || !e.snapshot.exists) return;
      final m = (e.snapshot.value ?? {}) as Map;
      final status = '${m['status'] ?? 'pending'}';
      if (status == 'approved') {
        final pts = await widget.db.getPoints(widget.phone);
        setState(() {
          _phase = 'done';
          _message = '🎁 แลกรางวัลสำเร็จ! ตอนนี้คุณมี $pts แต้มแล้ว';
        });
        await widget.tts.speak('แลกรางวัลสำเร็จ ตอนนี้คุณมี $pts แต้มแล้ว');
      } else if (status == 'rejected') {
        setState(() {
          _phase = 'rejected';
          _message = 'คำขอแลกถูกปฏิเสธแล้ว';
        });
        await widget.tts.speak(_message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stamps = List.generate(10, (i) {
      final filled = i < (widget.points >= 10 ? 10 : widget.points);
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? Colors.pinkAccent : Colors.grey.shade300,
        ),
      );
    });

    return AlertDialog(
      title: const Text('แลกแก้วฟรี', style: TextStyle(color: cocoa)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(spacing: 6, runSpacing: 6, children: stamps),
          const SizedBox(height: 12),
          Text(
            _message,
            style: const TextStyle(fontSize: 16, color: cocoa),
            textAlign: TextAlign.center,
          ),
          if (_phase == 'waiting') ...[
            const SizedBox(height: 12),
            const PrettySpinner(size: 90, ringThickness: 9),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        if (_phase == 'select' && widget.redeemable == 0)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: const Text('ปิด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        if (_phase == 'select' && widget.redeemable > 0)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.redeemable, (i) {
              final c = i + 1;
              return ElevatedButton(
                onPressed: () => _sendRedeem(c),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text('แลก $c แก้ว', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              );
            }),
          ),
        if (_phase == 'done' || _phase == 'rejected')
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: const Text('ปิด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}
