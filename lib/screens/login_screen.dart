import 'package:app_do_cu/UserProvider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:provider/provider.dart';
import 'register_screen.dart';
import 'home_screen.dart'; // Import trang chủ của bạn
import 'package:app_do_cu/showError.dart';
import 'admin_approval_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Trạng thái chờ

  // Khai báo Controller để lấy dữ liệu nhập vào
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Hàm xử lý đăng nhập
    Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      context.showError('Vui lòng nhập đầy đủ email và mật khẩu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. ĐĂNG NHẬP THÔNG QUA FIREBASE AUTH
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. LẤY THÔNG TIN ROLE TỪ REALTIME DATABASE
      String uid = userCredential.user!.uid;
      DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$uid");
      DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> userData = Map<dynamic, dynamic>.from(snapshot.value as Map);
        String role = userData['role'] ?? 'user';

        if (!mounted) return;
        
        // Lưu UID vào Provider để các màn hình khác sử dụng
        Provider.of<UserProvider>(context, listen: false).setUserId(uid);

        // Điều hướng dựa trên Role
        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminApprovalScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      }
    } on FirebaseAuthException catch (e) {
      // Firebase Auth sẽ tự trả về lỗi nếu sai mật khẩu hoặc không có user
      if (e.code == 'user-not-found') {
        context.showError('Email này không tồn tại trong hệ thống');
      } else if (e.code == 'wrong-password') {
        context.showError('Mật khẩu không chính xác. Vui lòng thử lại');
      } else {
        context.showError('Đã có lỗi xảy ra: ${e.message}');
      }
    } catch (e) {
      context.showError('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: Center(
        child: Container(
          width: 480,
          color: Colors.white,
          child: Column(
            children: [
              _buildTopAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        'Đăng Nhập',
                        style: GoogleFonts.lexend(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111418),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kết nối cộng đồng sinh viên trao đổi đồ cũ, bảo vệ môi trường.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Color(0xFF4E6172)),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildInputLabel('Email sinh viên'),
                      TextField(
                        controller: _emailController, // Gán controller
                        decoration: _buildInputDecoration('Nhập email sinh viên của bạn'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      _buildInputLabel('Mật khẩu'),
                      TextField(
                        controller: _passwordController, // Gán controller
                        obscureText: !_isPasswordVisible,
                        decoration: _buildInputDecoration('Nhập mật khẩu').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF617589),
                            ),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login, // Gọi hàm login
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF137FEC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Đăng Nhập', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Chưa có tài khoản?', style: TextStyle(color: Color(0xFF4E6172))),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Đăng ký ngay',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF137FEC)),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      _buildFooterIllustration(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111418))),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF617589)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDBE0E6))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDBE0E6))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF137FEC), width: 2)),
    );
  }

  Widget _buildFooterIllustration() {
    return Container(
      width: double.infinity,
      height: 128,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [const Color(0xFF137FEC).withOpacity(0.1), const Color(0xFF137FEC).withOpacity(0.05)]),
        border: Border.all(color: const Color(0xFF137FEC).withOpacity(0.1)),
      ),
      child: const Center(child: Text('HỆ THỐNG AN TOÀN & MINH BẠCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0x99137FEC), letterSpacing: 1.5))),
    );
  }

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 60.0, left: 16.0, right: 16.0, bottom: 16.0),
      child: Row(
        children: [
          Expanded(child: Text('Hệ Thống Trao Đổi', textAlign: TextAlign.center, style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111418)))),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}