import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/database_service.dart';

class RedeemPopup extends StatefulWidget {
  final String phone;
  final int points;
  final int redeemable;
  final DatabaseService db;
  final FlutterTts tts;
  final bool waitForApproval;

  const RedeemPopup({
    super.key,
    required this.phone,
    required this.points,
    required this.redeemable,
    required this.db,
    required this.tts,
    this.waitForApproval = false,
  });

  @override
  State<RedeemPopup> createState() => _RedeemPopupState();
}

class _RedeemPopupState extends State<RedeemPopup> {
  String message = '';
  late Stream<Map<String, dynamic>>? listener;

  @override
  void initState() {
    super.initState();
    if (widget.waitForApproval) {
      message = 'รอแอดมินอนุมัติ...';
      _startListeningApproval();
    } else {
      message = 'คุณมี ${widget.points} คะแนน\nสามารถแลกได้ ${widget.redeemable} แก้ว';
      widget.tts.speak(message);
    }
  }

  void _startListeningApproval() {
    listener = widget.db.listenRedeemStatus(widget.phone);
    listener!.listen((data) async {
      final status = data['status'] ?? '';
      if (status == 'approved') {
        setState(() => message = '🎉 แลกแก้วสำเร็จ!');
        await widget.tts.speak('แลกแก้วสำเร็จ!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop('approved');
      } else if (status == 'rejected') {
        setState(() => message = '❌ แอดมินไม่อนุมัติ');
        await widget.tts.speak('แอดมินไม่อนุมัติ');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop('rejected');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (!widget.waitForApproval)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('redeem_info_shown'),
              child: const Text('ปิด'),
            ),
        ],
      ),
    );
  }
}
