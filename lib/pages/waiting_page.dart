import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/database_service.dart';

class WaitingPage extends StatefulWidget {
  final String phone;
  const WaitingPage({super.key, required this.phone});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  final db = DatabaseService();
  Stream<DatabaseEvent>? _stream;
  String status = 'pending';

  @override
  void initState() {
    super.initState();
    _stream = db.lastRequestByPhone(widget.phone).onValue;
    _stream!.listen((e) {
      if (!mounted) return;
      if (e.snapshot.children.isEmpty) return;
      final item = e.snapshot.children.first.value as Map;
      setState(() => status = '${item['status']}');
    });
  }

  @override
  Widget build(BuildContext context) {
    String msg;
    if (status == 'pending') msg = 'รอแม่ค้าแจกแต้มแป๊ปนึงนะคะ';
    else if (status == 'approved') msg = 'สะสมแต้มเสร็จแล้ว ขอบคุณค่ะ';
    else if (status == 'rejected') msg = 'คำขอถูกปฏิเสธแล้ว';
    else msg = 'กำลังรอตรวจสอบ...';

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('เบอร์: ${widget.phone}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
