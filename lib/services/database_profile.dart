import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Dùng XFile thay cho File
import 'cloudinary_service.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final CloudinaryService _cloudinary = CloudinaryService();

  // 1. Lấy dữ liệu người dùng
  Future<Map<dynamic, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _db.child('users/$userId').get().timeout(const Duration(seconds: 10));
      if (snapshot.exists) {
        return Map<dynamic, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print("Lỗi lấy dữ liệu user: $e");
      return null;
    }
  }

  // 2. Cập nhật Avatar (Đồng bộ key 'avatarUrl' với các màn hình khác)
  Future<void> updateAvatar(String userId, String imageUrl) async {
    await _db.child('users/$userId').update({
      'avatarUrl': imageUrl, // Thống nhất dùng avatarUrl
    });
  }

  // 3. Xử lý chọn ảnh, tải lên Cloudinary và lưu link vào Firebase
  // SỬA LỖI: Chuyển từ File sang XFile để chạy được trên Web
  Future<String?> uploadAndSaveAvatar(String userId) async {
    // 1. Chọn ảnh (Hàm pickImage của CloudinaryService giờ trả về XFile)
    XFile? image = await _cloudinary.pickImage(); 
    if (image == null) return null;

    // 2. Tải lên Cloudinary (Hàm uploadImage nhận XFile)
    String? imageUrl = await _cloudinary.uploadImage(image, folderName: 'avatars'); 
    
    if (imageUrl != null) {
      // 3. Lưu link vào Firebase với key 'avatarUrl'
      await _db.child('users/$userId').update({'avatarUrl': imageUrl}); 
      return imageUrl;
    }
    return null;
  }

  // 4. Cập nhật thông tin sinh viên
  Future<bool> updateStudentInfo({
    required String uid,
    required String fullName,
    required String phone,
    required String studentId,
    required String school,
  }) async {
    try {
      // Sử dụng .update để giữ nguyên các trường khác (như email)
      await _db.child("users/$uid").update({
        "fullName": fullName,
        "phone": phone,
        "studentId": studentId,
        "address": school, // Dùng address để lưu tên trường
        "lastUpdated": ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      print("Lỗi khi cập nhật sinh viên: $e");
      return false;
    }
  }
}