import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RedeemRequestWidget extends StatefulWidget {
  final DatabaseReference dbRef;
  const RedeemRequestWidget({super.key, required this.dbRef});

  @override
  State<RedeemRequestWidget> createState() => _RedeemRequestWidgetState();
}

class _RedeemRequestWidgetState extends State<RedeemRequestWidget> {
  List<Map<String, dynamic>> _latestRedeemRequests = [];

  @override
  void initState() {
    super.initState();
    _listenRedeemRequests();
  }

  void _listenRedeemRequests() {
    widget.dbRef.child('redeem_requests').orderByChild('timestamp').limitToLast(2).onValue.listen((event) {
      final snap = event.snapshot;
      final tempList = <Map<String, dynamic>>[];
      if (snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        data.forEach((key, value) {
          final entry = Map<String, dynamic>.from(value);
          entry['key'] = key;
          final ts = entry['timestamp'];
          if (ts is int) entry['timestamp'] = ts < 1000000000000 ? ts * 1000 : ts;
          tempList.add(entry);
        });
        tempList.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      }
      setState(() => _latestRedeemRequests = tempList);
    });
  }

  void _approveRedeem(String key) async {
    final snap = await widget.dbRef.child('redeem_requests').child(key).get();
    if (!snap.exists) return;
    final data = snap.value as Map;
    final phone = data['phone'] as String;
    final count = (data['count'] as int?) ?? 0;
    final pointsRef = widget.dbRef.child('customers').child(phone).child('points');
    final currentSnap = await pointsRef.get();
    final currentPoints = (currentSnap.value as int?) ?? 0;
    final deductPoints = count * 10;
    if (currentPoints >= deductPoints) {
      await pointsRef.set(currentPoints - deductPoints);
      await widget.dbRef.child('redeem_requests').child(key).update({'status': 'approved'});
    } else {
      await widget.dbRef.child('redeem_requests').child(key).update({'status': 'rejected'});
    }
  }

  void _rejectRedeem(String key) async {
    await widget.dbRef.child('redeem_requests').child(key).update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('คำขอแลกแก้วล่าสุด 2 รายการ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._latestRedeemRequests.map((req) {
          final phone = req['phone'] ?? '';
          final count = req['count'] ?? 0;
          final status = req['status'] ?? 'pending';
          final date = DateTime.fromMillisecondsSinceEpoch(req['timestamp'] ?? 0);
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('เบอร์: $phone'),
                  Text('จำนวนแก้ว: $count'),
                  Text('สถานะ: $status'),
                  Text('เวลา: ${date.hour}:${date.minute.toString().padLeft(2,'0')}'),
                  if (status == 'pending')
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _approveRedeem(req['key']),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('อนุมัติ'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _rejectRedeem(req['key']),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                          child: const Text('ปฏิเสธ'),
                        ),
                      ],
                    )
                  else
                    const Text('สถานะแล้ว', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
