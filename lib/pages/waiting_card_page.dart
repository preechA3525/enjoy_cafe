import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class WaitingCardPage extends StatefulWidget {
  final String phoneNumber;
  const WaitingCardPage({super.key, required this.phoneNumber});

  @override
  State<WaitingCardPage> createState() => _WaitingCardPageState();
}

class _WaitingCardPageState extends State<WaitingCardPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("transactions");

  @override
  void initState() {
    super.initState();
    _addTransaction();
  }

  Future<void> _addTransaction() async {
    await _dbRef.runTransaction((mutableData) {
      final List transactions = (mutableData as List?) ?? [];
      transactions.add({
        "phone": widget.phoneNumber,
        "time": DateTime.now().toIso8601String(),
      });
      return Transaction.success(transactions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              "กรุณาแตะบัตร...",
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
