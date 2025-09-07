import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _pointsListener;
  StreamSubscription<DatabaseEvent>? _redeemListener;

  List<Map<String, dynamic>> _latestPointRequests = [];
  List<Map<String, dynamic>> _latestRedeemRequests = [];

  @override
  void initState() {
    super.initState();
    _listenPointRequests();
    _listenRedeemRequests();
  }

  void _listenPointRequests() {
    _pointsListener?.cancel();
    _pointsListener =
        dbRef.child('point_requests').orderByChild('timestamp').limitToLast(2).onValue.listen((event) {
      final snap = event.snapshot;
      final tempList = <Map<String, dynamic>>[];
      if (snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        data.forEach((key, value) {
          final entry = Map<String, dynamic>.from(value);
          entry['key'] = key;
          tempList.add(entry);
        });
        tempList.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      }
      setState(() => _latestPointRequests = tempList);
    });
  }

  void _listenRedeemRequests() {
    _redeemListener?.cancel();
    _redeemListener =
        dbRef.child('redeem_requests').orderByChild('timestamp').limitToLast(2).onValue.listen((event) {
      final snap = event.snapshot;
      final tempList = <Map<String, dynamic>>[];
      if (snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        data.forEach((key, value) {
          final entry = Map<String, dynamic>.from(value);
          entry['key'] = key;
          tempList.add(entry);
        });
        tempList.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      }
      setState(() => _latestRedeemRequests = tempList);
    });
  }

  void _givePoints(String requestKey, int points) async {
    final requestRef = dbRef.child('point_requests').child(requestKey);
    final snap = await requestRef.get();
    if (!snap.exists) return;

    final phone = (snap.value as Map)['phone'] as String;
    final pointsRef = dbRef.child('customers').child(phone).child('points');
    final currentSnap = await pointsRef.get();
    final currentPoints = (currentSnap.value as int?) ?? 0;

    await pointsRef.set(currentPoints + points);
    await requestRef.update({'status': 'approved', 'cups': points});
  }

  void _rejectPoint(String requestKey) async {
    await dbRef.child('point_requests').child(requestKey).update({'status': 'rejected'});
  }

  void _approveRedeem(String redeemKey) async {
    final redeemRef = dbRef.child('redeem_requests').child(redeemKey);
    final snap = await redeemRef.get();
    if (!snap.exists) return;

    final data = snap.value as Map;
    final phone = data['phone'] as String;
    final count = (data['count'] as int?) ?? 0;
    final pointsRef = dbRef.child('customers').child(phone).child('points');
    final currentSnap = await pointsRef.get();
    final currentPoints = (currentSnap.value as int?) ?? 0;

    final deductPoints = count * 10;
    if (currentPoints >= deductPoints) {
      await pointsRef.set(currentPoints - deductPoints);
      await redeemRef.update({'status': 'approved'});
    } else {
      await redeemRef.update({'status': 'rejected'});
    }
  }

  void _rejectRedeem(String redeemKey) async {
    await dbRef.child('redeem_requests').child(redeemKey).update({'status': 'rejected'});
  }

  @override
  void dispose() {
    _pointsListener?.cancel();
    _redeemListener?.cancel();
    super.dispose();
  }

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
            const Text('คำขอแต้มล่าสุด 2 รายการ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._latestPointRequests.map((req) {
              final phone = req['phone'] ?? '';
              final status = req['status'] ?? 'pending';
              final timestamp = req['timestamp'] ?? 0;
              final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('เบอร์: $phone'),
                      Text('สถานะ: $status'),
                      Text('เวลา: ${date.hour}:${date.minute.toString().padLeft(2,'0')}'),
                      const SizedBox(height: 6),
                      if (status == 'pending')
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...List.generate(10, (i) {
                              final points = i + 1;
                              return ElevatedButton(
                                onPressed: () => _givePoints(req['key'] as String, points),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: pinkButton,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(50, 50),
                                  textStyle: const TextStyle(fontSize: 18),
                                ),
                                child: Text('$points'),
                              );
                            }),
                            ElevatedButton(
                              onPressed: () => _rejectPoint(req['key'] as String),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(70, 50),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              child: const Text('ปฏิเสธ'),
                            ),
                          ],
                        )
                      else
                        const Text('อนุมัติแล้ว', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),
            const Text('คำขอแลกแก้วล่าสุด 2 รายการ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._latestRedeemRequests.map((req) {
              final phone = req['phone'] ?? '';
              final count = req['count'] ?? 0;
              final status = req['status'] ?? 'pending';
              final timestamp = req['timestamp'] ?? 0;
              final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
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
                      const SizedBox(height: 6),
                      if (status == 'pending')
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _approveRedeem(req['key'] as String),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('อนุมัติ'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _rejectRedeem(req['key'] as String),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
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
        ),
      ),
    );
  }
}
