
import 'package:app_do_cu/services/login_and_regist/email_service.dart' show EmailService;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';

enum OtpPurpose { register, resetPassword }

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String sentOtp;
  final OtpPurpose purpose; // Tham số để phân biệt mục đích
  final Map<String, dynamic>? userData; // Dữ liệu bổ sung nếu là đăng ký

  const OtpVerificationScreen({
    super.key, 
    required this.email, 
    required this.sentOtp, 
    required this.purpose,
    this.userData,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleVerification() async {
    final inputOtp = _otpController.text.trim();

    if (inputOtp != widget.sentOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mã OTP không chính xác"), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.purpose == OtpPurpose.resetPassword) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
        _showSuccessDialog("Khôi phục mật khẩu", "Liên kết đặt lại mật khẩu đã được gửi vào Email của bạn.");
      } else {
        await EmailService.createNewUser(
          email: widget.email,
          password: widget.userData!['password']!,
          name: widget.userData!['name']!,
        );
        _showSuccessDialog("Đăng ký thành công", "Tài khoản của bạn đã được tạo thành công!");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Hoàn tất"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.purpose == OtpPurpose.resetPassword ? "Xác thực khôi phục" : "Xác thực đăng ký")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Nhập mã 6 số đã gửi tới ${widget.email}", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: "000000", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerification,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Xác nhận"),
            ),
          ],
        ),
      ),
    );
  }
}