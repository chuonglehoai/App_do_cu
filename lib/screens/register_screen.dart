
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// THÊM 2 DÒNG IMPORT NÀY
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // Nên có thêm cái này

  // ĐƯA HÀM _signUp VÀO TRONG NÀY
  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin');
      return;
    }
    if (RegExp(r'[0-9]').hasMatch(name)) {
      _showError('Họ và tên không được chứa số');
      return;
    }
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9]).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      _showError('Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số');
      return;
    }
    if (password != confirmPassword) {
      _showError('Mật khẩu xác nhận không khớp');
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      DatabaseReference ref = FirebaseDatabase.instance.ref("users/${userCredential.user!.uid}");

    await ref.set({
      "fullName": name,
      "email": email,
      "uid": userCredential.user!.uid,
      'password': password,
      ''
      "createdAt": DateTime.now().toIso8601String(), // Realtime DB thích chuỗi String hoặc số
    });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công!')),
      );
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Đã có lỗi xảy ra')),
      );
    }
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red,),
    );
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
              _buildTopAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Text('Tạo Tài Khoản', style: GoogleFonts.lexend(fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),

                      // --- Full Name ---
                      _buildInputLabel('Họ và tên'),
                      TextField(
                        controller: _nameController, // GÁN Ở ĐÂY
                        decoration: _buildInputDecoration('Nhập họ tên đầy đủ'),
                      ),
                      const SizedBox(height: 16),

                      // --- Email ---
                      _buildInputLabel('Email sinh viên'),
                      TextField(
                        controller: _emailController, // GÁN Ở ĐÂY
                        decoration: _buildInputDecoration('name@student.edu.vn'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // --- Password ---
                      _buildInputLabel('Mật khẩu'),
                      TextField(
                        controller: _passwordController, // GÁN Ở ĐÂY
                        obscureText: !_isPasswordVisible,
                        decoration: _buildInputDecoration('Tạo mật khẩu mạnh').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Confirm Password ---
                      _buildInputLabel('Xác nhận mật khẩu'),
                      TextField(
                        controller: _confirmPasswordController, // GÁN Ở ĐÂY
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: _buildInputDecoration('Nhập lại mật khẩu').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- Register Button ---
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp, // Vô hiệu hóa khi đang load
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF137FEC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Đăng Ký Ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
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

  // Tái sử dụng các Helpers từ trang Login của bạn
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
      fillColor: const Color(0xFFF6F7F8), // Đổi nhẹ màu nền input cho phân biệt
      contentPadding: const EdgeInsets.all(15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF137FEC), width: 2)),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60.0, left: 16.0, right: 16.0, bottom: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF111418)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Tạo tài khoản mới',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF111418)),
            ),
          ),
          const SizedBox(width: 48), // Bù trừ cho nút back để tiêu đề nằm giữa
        ],
      ),
    );
  }
}
