import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PointRequestWidget extends StatefulWidget {
  final DatabaseReference dbRef;
  const PointRequestWidget({super.key, required this.dbRef});

  @override
  State<PointRequestWidget> createState() => _PointRequestWidgetState();
}

class _PointRequestWidgetState extends State<PointRequestWidget> {
  List<Map<String, dynamic>> _latestPointRequests = [];

  @override
  void initState() {
    super.initState();
    _listenPointRequests();
  }

  void _listenPointRequests() {
    widget.dbRef.child('point_requests').orderByChild('timestamp').limitToLast(2).onValue.listen((event) {
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
      setState(() => _latestPointRequests = tempList);
    });
  }

  void _givePoints(String key, int points) async {
    final snap = await widget.dbRef.child('point_requests').child(key).get();
    if (!snap.exists) return;
    final phone = (snap.value as Map)['phone'] as String;
    final pointsRef = widget.dbRef.child('customers').child(phone).child('points');
    final currentSnap = await pointsRef.get();
    final currentPoints = (currentSnap.value as int?) ?? 0;
    await pointsRef.set(currentPoints + points);
    await widget.dbRef.child('point_requests').child(key).update({'status': 'approved', 'cups': points});
  }

  void _rejectPoint(String key) async {
    await widget.dbRef.child('point_requests').child(key).update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    const pinkButton = Color(0xFFE91E63);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('คำขอแต้มล่าสุด 2 รายการ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._latestPointRequests.map((req) {
          final phone = req['phone'] ?? '';
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
                  Text('สถานะ: $status'),
                  Text('เวลา: ${date.hour}:${date.minute.toString().padLeft(2,'0')}'),
                  if (status == 'pending')
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...List.generate(10, (i) {
                          final points = i + 1;
                          return ElevatedButton(
                            onPressed: () => _givePoints(req['key'], points),
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
                          onPressed: () => _rejectPoint(req['key']),
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
      ],
    );
  }
}
