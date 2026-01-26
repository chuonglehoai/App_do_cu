import 'package:app_do_cu/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. Import file màn hình login ở đây
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hệ Thống Trao Đổi',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.lexendTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF137FEC),
          primary: const Color(0xFF137FEC),
          surface: const Color(0xFFF6F7F8),
        ),
      ),
      // 2. Sử dụng class đã tách
      home: const LoginScreen(), 
    );
  }
}