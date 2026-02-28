import 'dart:io';
import 'cloudinary_service.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final CloudinaryService _cloudinary = CloudinaryService();
  Future<Map<dynamic, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _db.child('users/$userId').get().timeout(const Duration(seconds: 10));
      if (snapshot.exists) {
        return Map<dynamic, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  // Hàm cập nhật Avatar
  Future<void> updateAvatar(String userId, String imageUrl) async {
    await _db.child('users/$userId').update({
      'avatar': imageUrl,
    });
  }
  // Hàm Update: Xử lý chọn ảnh, tải lên Cloudinary và lưu link vào Firebase
  Future<String?> uploadAndSaveAvatar(String userId) async {
    File? image = await _cloudinary.pickImage(); // Chọn ảnh
    if (image == null) return null;

    String? imageUrl = await _cloudinary.uploadImage(image); // Tải lên Cloudinary
    if (imageUrl != null) {
      await _db.child('users/$userId').update({'avatar': imageUrl}); // Lưu link vào Firebase
      return imageUrl;
    }
    return null;
  }
  // Hàm cập nhật thông tin sinh viên
  Future<bool> updateStudentInfo({
    required String uid,
    required String fullName,
    required String phone,
    required String studentId,
    required String school,
  }) async {
    try {
      // Sử dụng .update để chỉ ghi đè các trường này, giữ nguyên các trường khác (như email, avatar)
      await _db.child("users/$uid").update({
        "fullName": fullName,
        "phone": phone,
        "studentId": studentId,
        "address": school, // Bạn dùng 'address' để lưu tên trường như trong code Profile cũ
        "lastUpdated": ServerValue.timestamp, // Lưu dấu mốc thời gian cập nhật
      });
      return true; // Trả về true nếu thành công
    } catch (e) {
      print("Lỗi khi cập nhật sinh viên: $e");
      return false; // Trả về false nếu thất bại
    }
  }
}