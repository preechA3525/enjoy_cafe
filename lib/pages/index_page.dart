import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/keypad.dart';
import 'admin_page.dart';

class IndexPage extends StatefulWidget {
  final String phoneNumber;
  const IndexPage({super.key, this.phoneNumber = ''});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> with TickerProviderStateMixin {
  final FlutterTts tts = FlutterTts();
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late String phone;
  bool _isProcessing = false;
  int _currentPoints = 0;

  StreamSubscription<DatabaseEvent>? _currentListener;
  StreamSubscription<DatabaseEvent>? _pointsListener;

  // Cow animation
  late AnimationController _cowController;
  late Animation<double> _cowScale;
  Offset _cowOffset = const Offset(20, 400);

  // Logo tap exit
  int _logoTapCount = 0;
  Timer? _logoTapTimer;

  // Footer tap admin
  int _footerTapCount = 0;
  Timer? _footerTapTimer;

  bool get _phoneOk => phone.replaceAll(RegExp(r'[^0-9]'), '').length == 10;
  String get _cleanPhone => phone.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  void initState() {
    super.initState();
    phone = widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    tts.awaitSpeakCompletion(true);
    _listenPoints();

    // Cow bounce animation
    _cowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cowScale = TweenSequence([
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.5)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.5, end: 0.9)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.9, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
    ]).animate(_cowController);

    // Lock orientation & immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // -------------------- Listen points from Firebase --------------------
  void _listenPoints() {
    if (!_phoneOk) return;
    _pointsListener?.cancel();
    _pointsListener = dbRef
        .child('customers')
        .child(_cleanPhone)
        .child('points')
        .onValue
        .listen((event) {
      final snap = event.snapshot;
      setState(() {
        _currentPoints = (snap.value as num?)?.toInt() ?? 0;
      });
    });
  }

  void _add(String n) {
    final digit = n.replaceAll(RegExp(r'[^0-9]'), '');
    if (digit.isEmpty) return;
    if (_cleanPhone.length < 10) {
      setState(() => phone += digit);
      _listenPoints();
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _speak(String message) async => await tts.speak(message);

  Future<void> _playNotification() async {
    await _audioPlayer.play(AssetSource('assets/mmm-2-tone-sexy.mp3'));
  }

  // -------------------- Waiting Popup --------------------
  void _showWaitingPopup(
      {String message = 'รอแป๊ปนึงค๊ะ..',
      int? currentPoints,
      bool showTotal = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              if (currentPoints != null) ...[
                const SizedBox(height: 12),
                Text(
                  showTotal
                      ? 'แต้มสะสมใว้: $currentPoints ค่ะ'
                      : 'แต้มรวมตอนนี้: $currentPoints ค่ะ',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    for (int i = 0; i < (currentPoints / 10).ceil(); i++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          i == (currentPoints / 10).ceil() - 1
                              ? currentPoints % 10 == 0
                                  ? 10
                                  : currentPoints % 10
                              : 10,
                          (index) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child:
                                Icon(Icons.local_cafe, color: Colors.brown, size: 32),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- Add Points --------------------
  void _onRequestPoints() async {
    if (_isProcessing) return;

    _playNotification(); // 🔔 เล่นเสียงแจ้งเตือน

    if (!_phoneOk) {
      _showWaitingPopup(message: 'กรุณาใส่เบอร์โทรของคุณ');
      await _speak('กรุณาใส่เบอร์โทรของคุณ');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    _isProcessing = true;
    _currentListener?.cancel();

    final ref = dbRef.child('point_requests').push();
    final oldPoints = _currentPoints;

    await ref.set({
      'phone': _cleanPhone,
      'status': 'pending',
      'timestamp': ServerValue.timestamp,
    });

    _showWaitingPopup(message: 'รอแม่ค้าแป๊ปนึง...', currentPoints: oldPoints);
    await _speak('รอแป๊ปแม่ค้ากำลังให้แต้มคุณ');

    _currentListener = ref.onValue.listen((event) async {
      final snap = event.snapshot;
      if (snap.value == null) return;
      final data = Map<String, dynamic>.from(snap.value as Map);
      final status = data['status'] ?? '';
      final approvedPoints = (data['cups'] as num?)?.toInt() ?? 0;

      if (status == 'approved') {
        _currentListener?.cancel();
        Navigator.of(context).pop();

        final totalPoints = oldPoints + approvedPoints;
        await dbRef.child('customers').child(_cleanPhone).child('points').set(totalPoints);

        _cowController.forward(from: 0);

        _showWaitingPopup(
            message: '🎉 คุณได้เพิ่ม $approvedPoints แต้ม',
            currentPoints: totalPoints,
            showTotal: true);
        await _speak(
            'ตอนนี้คุณได้เพิ่ม $approvedPoints แต้ม รวมแต้มเดิมเป็น $totalPoints แต้มค่ะ');

        await Future.delayed(const Duration(seconds: 4));
        if (mounted) {
          Navigator.of(context).pop();
          setState(() {
            _currentPoints = totalPoints;
            phone = '';
          });
        }
      } else if (status == 'rejected') {
        _currentListener?.cancel();
        Navigator.of(context).pop();

        _showWaitingPopup(message: '❌ คำขอถูกปฏิเสธ', currentPoints: oldPoints);
        await _speak('คำขอถูกปฏิเสธค๊ะ');

        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.of(context).pop();
        setState(() => phone = '');
      }

      _isProcessing = false;
    });
  }

  // -------------------- Redeem --------------------
  void _showRedeemPopup() async {
    if (!_phoneOk) {
      _showWaitingPopup(message: 'กรุณาใส่เบอร์โทรของคุณ');
      await _speak('กรุณาใส่เบอร์โทรของคุณ');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    final maxRedeem = (_currentPoints ~/ 10);
    if (maxRedeem == 0) {
      _showNotEnoughPointsPopup();
      return;
    }

    _showWaitingPopup(message: 'เลือกจำนวนแก้วที่ต้องการแลก', currentPoints: _currentPoints);
    await _speak('กรุณาเลือกจำนวนแก้วที่ต้องการแลกค่ะ');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('เลือกจำนวนแก้วที่ต้องการแลก',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(maxRedeem, (i) {
                    int redeemCount = i + 1;
                    return GestureDetector(
                      onTap: () => _onRedeem(redeemCount),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/cup.png', width: 60, height: 60),
                          const SizedBox(height: 6),
                          Text('แลก $redeemCount แก้ว',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _showNotEnoughPointsPopup() async {
    final points = _currentPoints;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('แต้มยังไม่พอสำหรับแลกแก้ว',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  points,
                  (index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(Icons.local_cafe, color: Colors.brown, size: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await _speak('แต้มคุณยังไม่พอสำหรับแลกแก้วค่ะ');
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => phone = '');
      }
    });
  }

  void _onRedeem(int count) async {
    Navigator.of(context).pop();
    if (_isProcessing) return;
    if (!_phoneOk) return;

    _isProcessing = true;
    final deductPoints = count * 10;

    if (_currentPoints < deductPoints) {
      _showNotEnoughPointsPopup();
      _isProcessing = false;
      return;
    }

    final requestRef = dbRef.child('redeem_requests').push();
    final oldPoints = _currentPoints;

    await requestRef.set({
      'phone': _cleanPhone,
      'count': count,
      'status': 'pending',
      'timestamp': ServerValue.timestamp,
    });

    _showWaitingPopup(message: 'รอร้านยืนยัน...', currentPoints: oldPoints);

    _currentListener = requestRef.onValue.listen((event) async {
      final snap = event.snapshot;
      if (snap.value == null) return;
      final data = Map<String, dynamic>.from(snap.value as Map);
      final status = data['status'] ?? '';

      if (status == 'approved') {
        _currentListener?.cancel();
        Navigator.of(context).pop();

        final remainingPoints = (oldPoints - deductPoints).clamp(0, oldPoints).toInt();
        await dbRef.child('customers').child(_cleanPhone).child('points').set(remainingPoints);

        _showWaitingPopup(
            message: '🎉 แลกแก้วสำเร็จ! -$deductPoints แต้ม',
            currentPoints: remainingPoints,
            showTotal: true);
        await _speak('คุณแลกแก้วสำเร็จแล้วค่ะ ใช้ไป $deductPoints แต้ม');
        await Future.delayed(const Duration(seconds: 4));
        if (mounted) {
          Navigator.of(context).pop();
          setState(() {
            _currentPoints = remainingPoints;
            phone = '';
          });
        }
      } else if (status == 'rejected') {
        _currentListener?.cancel();
        Navigator.of(context).pop();

        _showWaitingPopup(message: '❌ คำขอถูกปฏิเสธ', currentPoints: oldPoints);
        await _speak('คำขอแลกแก้วถูกปฏิเสธค๊ะ');

        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.of(context).pop();
        setState(() => phone = '');
      }

      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    _currentListener?.cancel();
    _pointsListener?.cancel();
    _cowController.dispose();
    _logoTapTimer?.cancel();
    _footerTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pastelTop = Color(0xFFFFEBF2);
    const pastelBottom = Color(0xFFFFDDEB);
    const pinkButton = Color(0xFFE91E63);

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [pastelTop, pastelBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            // LOGO Tap Exit
                            GestureDetector(
                              onTap: () {
                                _logoTapCount++;
                                _logoTapTimer?.cancel();
                                _logoTapTimer = Timer(const Duration(seconds: 2), () {
                                  _logoTapCount = 0;
                                });

                                if (_logoTapCount >= 5) {
                                  _logoTapCount = 0;
                                  _logoTapTimer?.cancel();
                                  _exitApp();
                                }
                              },
                              child: Image.asset('assets/logo.png', width: 120, height: 120),
                            ),
                            const SizedBox(height: 8),
                            const Text('สะสมแต้ม Enjoy Cafe',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0x22CC0066), width: 2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                phone.isEmpty ? 'กรอกเบอร์โทรศัพท์' : phone,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.32,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Keypad(
                                  onNumber: _add,
                                  onBackspace: () => setState(() => phone =
                                      phone.isNotEmpty
                                          ? phone.substring(0, phone.length - 1)
                                          : ''),
                                  onClear: () => setState(() => phone = ''),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: _onRequestPoints,
                                      icon: const Icon(Icons.mail_outline),
                                      label: const Text('สะสมแต้ม',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18)),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: pinkButton,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: _showRedeemPopup,
                                      icon: const Icon(Icons.card_giftcard),
                                      label: const Text('แลกแก้วฟรี',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18)),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Footer Tap Admin
                            GestureDetector(
                              onTap: () {
                                _footerTapCount++;
                                _footerTapTimer?.cancel();
                                _footerTapTimer = Timer(const Duration(seconds: 2), () {
                                  _footerTapCount = 0;
                                });

                                if (_footerTapCount >= 5) {
                                  _footerTapCount = 0;
                                  _footerTapTimer?.cancel();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => AdminPage()),
                                  );
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Text('Enjoy Cafe 095-8715247',
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Cow Draggable
        Positioned(
          left: _cowOffset.dx,
          top: _cowOffset.dy,
          child: Draggable(
            feedback: SizedBox(
              width: 350,
              height: 350,
              child: ScaleTransition(
                scale: _cowScale,
                child: Lottie.asset('assets/A fitness cow.json'),
              ),
            ),
            childWhenDragging: const SizedBox.shrink(),
            onDragEnd: (details) {
              setState(() => _cowOffset = details.offset);
            },
            child: SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset('assets/A fitness cow.json'),
            ),
          ),
        ),
      ],
    );
  }

  void _exitApp() {
    Future.delayed(Duration.zero, () {
      SystemNavigator.pop();
    });
  }
}
