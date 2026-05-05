import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, UserCredential;
import 'package:firebase_database/firebase_database.dart' show FirebaseDatabase, DatabaseReference;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class EmailService {
  static const String serviceId = 'app_do_cu';
  static const String templateId = 'template_g2cdqig';
  static const String userId = 'x5DMNpK4ZCm6EdszE';

  static String generateOtp() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  static Future<void> sendOtpEmail(String recipientEmail, String otp) async {
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
  // Chức năng tạo tài khoản mới sau khi xác thực OTP thành công
  static Future<void> createNewUser({
    required String email,
    required String password,
    required String name,
  }) async {
    // 1. Tạo tài khoản trên FirebaseAuth
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // 2. Lưu thông tin bổ sung vào Realtime Database
    DatabaseReference ref = FirebaseDatabase.instance.ref("users/${userCredential.user!.uid}");
    await ref.set({
      "address": '',
      "fullName": name,
      "email": email,
      "uid": userCredential.user!.uid,
      "createdAt": DateTime.now().toIso8601String(),
      'role': 'user',
      'password': password, // Lưu ý: thực tế không nên lưu pass plain text, đây là theo logic cũ của bạn
    });
  }
}