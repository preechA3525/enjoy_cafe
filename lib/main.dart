import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/index_page.dart';
import 'pages/admin_page.dart'; // อยู่โฟลเดอร์เดียวกับ index_page.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Enjoy Cafe',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.maliTextTheme(),
      ),
      home: const IndexPage(), // หน้าแรกเป็น IndexPage
      routes: {
        '/admin': (_) => const AdminPage(), // route สำหรับ AdminPage
      },
    );
  }
}
