import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../UserProvider.dart'; // Đảm bảo đúng đường dẫn tới Provider của bạn

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
    required Function(bool) onLoading,
    required Function(String) onError,
    required Function(String role) onSuccess,
  }) async {
    // Kiểm tra dữ liệu đầu vào
    if (email.isEmpty || password.isEmpty) {
      onError('Vui lòng nhập đầy đủ email và mật khẩu');
      return;
    }

    onLoading(true);

    try {
      // 1. ĐĂNG NHẬP THÔNG QUA FIREBASE AUTH
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // 2. KIỂM TRA TÀI KHOẢN ADMIN TRƯỚC
      DataSnapshot adminSnapshot = await _db.ref("admins/$uid").get();

      if (adminSnapshot.exists) {
        // Lưu UID vào Provider
        Provider.of<UserProvider>(context, listen: false).setUserId(uid);
        onSuccess('admin');
        return;
      }

      // 3. NẾU KHÔNG PHẢI ADMIN, KIỂM TRA TÀI KHOẢN USER
      DataSnapshot userSnapshot = await _db.ref("users/$uid").get();

      if (userSnapshot.exists) {
        Provider.of<UserProvider>(context, listen: false).setUserId(uid);
        onSuccess('user');
      } else {
        onError('Tài khoản chưa được thiết lập dữ liệu trên hệ thống.');
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        onError('Email này không tồn tại trong hệ thống');
      } else if (e.code == 'wrong-password') {
        onError('Mật khẩu không chính xác. Vui lòng thử lại');
      } else {
        onError('Lỗi xác thực: ${e.message}');
      }
    } catch (e) {
      onError('Lỗi kết nối: $e');
    } finally {
      onLoading(false);
    }
  }
}