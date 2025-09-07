import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // === สะสมแต้ม ===
  Future<String> sendPointRequest({required String phone}) async {
    final ref = _db.child('point_requests').push();
    await ref.set({
      'phone': phone,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return ref.key!;
  }

  DatabaseReference requestRefById(String requestId) =>
      _db.child('point_requests/$requestId');

  // === แต้มรวมลูกค้า ===
  Future<int> getPoints(String phone) async {
    final snap = await _db.child('customers/$phone/points').get();
    if (!snap.exists) return 0;
    final v = snap.value;
    return (v is int) ? v : int.tryParse('$v') ?? 0;
  }

  // === แลกรางวัล (10 แต้ม = 1 แก้ว) ===
  Future<void> sendRedeemRequest({required String phone, required int count}) async {
    await _db.child('redeem_requests/$phone').set({
      'phone': phone,
      'count': count,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  DatabaseReference redeemRefByPhone(String phone) =>
      _db.child('redeem_requests/$phone');

  // === Listener สำหรับรอ admin อนุมัติ ===
  Stream<Map<String, dynamic>> listenRedeemStatus(String phone) {
    return _db.child('redeem_requests/$phone').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return {};
    });
  }

  // (เผื่อใช้ที่อื่น)
  Query lastRequestByPhone(String phone) => _db
      .child('point_requests').orderByChild('phone').equalTo(phone).limitToLast(1);
}
