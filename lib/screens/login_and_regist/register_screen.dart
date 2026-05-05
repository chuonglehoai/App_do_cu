import 'package:app_do_cu/services/login_and_regist/email_service.dart' show EmailService;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // --- LOGIC XỬ LÝ ---

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  bool _validateForm() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ thông tin');
      return false;
    }

    if (RegExp(r'[0-9]').hasMatch(name)) {
      _showSnackBar('Họ và tên không được chứa số');
      return false;
    }

    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9]).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      _showSnackBar('Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số');
      return false;
    }

    if (password != confirmPassword) {
      _showSnackBar('Mật khẩu xác nhận không khớp');
      return false;
    }

    return true;
  }

  Future<void> _handleSignUpStep1() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Tạo mã OTP từ Service
      String otp = EmailService.generateOtp();

      // 2. Gửi Email thông qua Service
      await EmailService.sendOtpEmail(_emailController.text.trim(), otp);

      if (!mounted) return;

      // 3. Chuyển hướng sang màn hình OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: _emailController.text.trim(),
            sentOtp: otp,
            purpose: OtpPurpose.register,
            userData: {
              'name': _nameController.text.trim(),
              'password': _passwordController.text,
            },
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- GIAO DIỆN (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: Center(
        child: Container(
          width: 480, // Giới hạn chiều rộng cho giao diện web/tablet
          color: Colors.white,
          child: Column(
            children: [
              _buildTopAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildRegisterForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          'Tạo Tài Khoản',
          style: GoogleFonts.lexend(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        
        _buildInputLabel('Họ và tên'),
        TextField(
          controller: _nameController,
          decoration: _buildInputDecoration('Nhập họ tên đầy đủ'),
        ),
        
        const SizedBox(height: 16),
        _buildInputLabel('Email sinh viên'),
        TextField(
          controller: _emailController,
          decoration: _buildInputDecoration('name@student.edu.vn'),
          keyboardType: TextInputType.emailAddress,
        ),
        
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
        _buildSubmitButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUpStep1,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF137FEC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Gửi Mã Xác Thực',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111418),
          ),
        ),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF137FEC), width: 2),
      ),
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
              'Đăng ký tài khoản mới',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111418),
              ),
            ),
          ),
          const SizedBox(width: 48), // Cân bằng với nút back
        ],
      ),
    );
  }
}