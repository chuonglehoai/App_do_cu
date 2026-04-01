import 'package:firebase_database/firebase_database.dart';

class UserService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('users');

  // Hàm lấy thông tin chi tiết người dùng từ ID
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final snapshot = await _dbRef.child(userId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print("Lỗi khi lấy thông tin user: $e");
    }
    return null;
  }
}