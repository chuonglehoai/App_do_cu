import 'package:app_do_cu/screens/login_and_regist/otp_verification_screen.dart' show OtpVerificationScreen, OtpPurpose;
import 'package:app_do_cu/services/login_and_regist/email_service.dart' show EmailService;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_do_cu/showError.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  // BƯỚC 1: Gửi mã OTP về Mail để xác thực chính chủ
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      context.showError('Vui lòng nhập email sinh viên của bạn');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Tạo OTP 6 số ngẫu nhiên
      String otp = EmailService.generateOtp();
      
      // 2. Gửi OTP qua mail bằng EmailJS (thông qua service đã tách)
      await EmailService.sendOtpEmail(email, otp);
      
      if (!mounted) return;
      
      // 3. Chuyển sang trang nhập OTP. 
      // Chỉ khi người dùng nhập đúng OTP ở màn hình này, lệnh Reset mật khẩu mới được thực thi.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: email, sentOtp: otp, purpose: OtpPurpose.resetPassword,),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi gửi mã: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111418), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset, size: 64, color: Color(0xFF137FEC)),
              ),
              const SizedBox(height: 32),
              Text(
                'Khôi phục mật khẩu',
                style: GoogleFonts.lexend(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111418),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bước 1: Nhập email để nhận mã xác thực OTP.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF4E6172), height: 1.5),
              ),
              const SizedBox(height: 40),
              _buildInputLabel('Email sinh viên'),
              TextField(
                controller: _emailController,
                decoration: _buildInputDecoration('name@student.edu.vn'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),

              // NÚT BẤM ĐÃ ĐƯỢC SỬA: Gọi hàm _handleSendOtp thay vì _resetPassword
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Gửi mã xác thực', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Quay lại Đăng nhập',
                  style: TextStyle(color: Color(0xFF617589), fontWeight: FontWeight.w500),
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
}