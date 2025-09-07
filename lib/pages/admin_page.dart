import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/point_request_widget.dart';
import '../widgets/redeem_request_widget.dart';
import '../widgets/report_by_date_widget.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    const pinkButton = Color(0xFFE91E63);
    const bgColor = Color(0xFFFFEBF2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Admin - Enjoy Cafe'),
        backgroundColor: pinkButton,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            // แสดงคำขอแต้มล่าสุด 2 รายการ
            PointRequestWidget(dbRef: dbRef),
            const SizedBox(height: 24),
            // แสดงคำขอแลกแก้วล่าสุด 2 รายการ
            RedeemRequestWidget(dbRef: dbRef),
            const SizedBox(height: 24),
            // แสดงรายงานการให้แต้มตามวันที่
            ReportByDateWidget(dbRef: dbRef),
          ],
        ),
      ),
    );
  }
}
