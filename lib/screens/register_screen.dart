import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final TextEditingController _confirmPasswordController = TextEditingController(); 
  final TextEditingController _otpController = TextEditingController();

  String? _sentOtp; 
  bool _isVerificationMode = false; 

  String _generateOtp() {
    return (Random().nextInt(900000) + 100000).toString();
  }
  
  Future<void> _sendOtpEmail(String recipientEmail, String otp) async {
  const serviceId = 'app_do_cu';
  const templateId = 'template_g2cdqig';
  const userId = 'x5DMNpK4ZCm6EdszE';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'to_email': recipientEmail,
        'otp_code': otp,
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Không thể gửi mail: ${response.body}');
  }
}

  // Bước 1: Kiểm tra thông tin và gửi OTP
  Future<void> _handleInitialSignUp() async {
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
      _sentOtp = _generateOtp();
      await _sendOtpEmail(email, _sentOtp!);
      
      setState(() {
        _isVerificationMode = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã xác thực đã được gửi tới Email của bạn')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  // Bước 2: Xác nhận OTP và tạo tài khoản chính thức
  Future<void> _verifyAndCreateAccount() async {
    if (_otpController.text.trim() != _sentOtp) {
      _showError('Mã OTP không chính xác');
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      DatabaseReference ref = FirebaseDatabase.instance.ref("users/${userCredential.user!.uid}");
      await ref.set({
        "fullName": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "uid": userCredential.user!.uid,
        "createdAt": DateTime.now().toIso8601String(),
        'role': 'user', 
        'password': _passwordController.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); 
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Lỗi đăng ký');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
                  child: _isVerificationMode ? _buildOtpForm() : _buildRegisterForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Form xác thực mã OTP
  Widget _buildOtpForm() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text('Xác thực Email', style: GoogleFonts.lexend(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text('Mã OTP đã được gửi đến:\n${_emailController.text}', textAlign: TextAlign.center),
        const SizedBox(height: 32),
        _buildInputLabel('Nhập mã xác thực'),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
          decoration: _buildInputDecoration('000000'),
        ),
        const SizedBox(height: 32),
        _buildButton('Xác Nhận & Đăng Ký', _verifyAndCreateAccount),
        TextButton(
          onPressed: () => setState(() => _isVerificationMode = false),
          child: const Text('Quay lại chỉnh sửa thông tin'),
        )
      ],
    );
  }

  // Form nhập thông tin đăng ký ban đầu
  Widget _buildRegisterForm() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text('Tạo Tài Khoản', style: GoogleFonts.lexend(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        _buildInputLabel('Họ và tên'),
        TextField(controller: _nameController, decoration: _buildInputDecoration('Nhập họ tên đầy đủ')),
        const SizedBox(height: 16),
        _buildInputLabel('Email sinh viên'),
        TextField(controller: _emailController, decoration: _buildInputDecoration('name@student.edu.vn'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildInputLabel('Mật khẩu'),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: _buildInputDecoration('Tạo mật khẩu mạnh').copyWith(
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInputLabel('Xác nhận mật khẩu'),
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: _buildInputDecoration('Nhập lại mật khẩu').copyWith(
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildButton('Gửi Mã Xác Thực', _handleInitialSignUp),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF137FEC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      fillColor: const Color(0xFFF6F7F8),
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}