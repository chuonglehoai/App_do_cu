import 'package:firebase_database/firebase_database.dart';

class DatabaseProduct {
  final DatabaseReference _rootRef = FirebaseDatabase.instance.ref();

  // 1. LẤY ĐỊA CHỈ NGƯỜI DÙNG
  Future<String> getUserAddress(String userId) async {
    try {
      final snapshot = await _rootRef.child('users/$userId/address').get();
      return snapshot.exists ? snapshot.value.toString() : "Địa chỉ chưa cập nhật";
    } catch (e) {
      return "Lỗi lấy địa chỉ";
    }
  }

  // 2. THÊM BÀI ĐĂNG MỚI (Mặc định vào node 'posts' với status 'pending')
  Future<bool> addPost({
    required String sellerId,
    required String title,
    required String category,
    required String type,
    required String price,
    required String description,
    required List<String> imageUrls,
    required String address,
  }) async {
    try {
      // Bài mới luôn nằm trong node 'posts' để chờ Admin duyệt
      final newPostRef = _rootRef.child("posts").push(); 
      
      await newPostRef.set({
        'sellerId': sellerId,
        'title': title,
        'category': category,
        'type': type,
        'price': price,
        'description': description,
        'images': imageUrls,
        'address': address,
        'status': 'pending', // Trạng thái chờ duyệt
        'createdAt': ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      print("Lỗi thêm tin đăng: $e");
      return false;
    }
  }

  // 3. CẬP NHẬT BÀI ĐĂNG (Dành cho chức năng "Thay đổi" và "Đăng lại")
  Future<bool> updatePost({
    required String productId,
    required String oldStatus,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (oldStatus == 'approved') {
        // Nếu bài đã đăng (node 'posted'), cần tìm theo category để update
        String category = data['category'];
        await _rootRef.child("posted/$category/$productId").update(data);
      } else {
        // Nếu bài ở node 'posts' (pending hoặc refused)
        await _rootRef.child("posts/$productId").update(data);
      }
      return true;
    } catch (e) {
      print("Lỗi cập nhật bài đăng: $e");
      return false;
    }
  }

  // 4. XÓA TIN ĐĂNG (Tối ưu: Truy cập trực tiếp địa chỉ node)
  Future<bool> deletePost(String productId, String status, String category) async {
    try {
      if (status == 'approved') {
        // TỐI ƯU: Không tải toàn bộ node 'posted' về nữa.
        // Vì đã có 'category', ta trỏ thẳng đến đường dẫn để xóa ngay lập tức.
        await _rootRef.child("posted").child(category).child(productId).remove();
        return true;
      } else {
        // Nếu bài đang chờ hoặc bị từ chối, xóa thẳng trong 'posts'
        await _rootRef.child("posts").child(productId).remove();
        return true;
      }
    } catch (e) {
      print("Lỗi xóa bài: $e");
      return false;
    }
  }

  // 5. LẤY DANH SÁCH TIN ĐÃ DUYỆT THEO DANH MỤC
  Future<List<Map<dynamic, dynamic>>> getPostsByCategory(String category) async {
    try {
      DataSnapshot snapshot = await _rootRef.child("posted").child(category).get();
      List<Map<dynamic, dynamic>> posts = [];
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          var postData = Map<dynamic, dynamic>.from(value);
          postData['id'] = key; 
          posts.add(postData);
        });
      }
      return posts;
    } catch (e) {
      return [];
    }
  }
}