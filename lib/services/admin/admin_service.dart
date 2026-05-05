import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AdminService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getPendingPostsStream() {
    return _dbRef.child("posts").onValue;
  }

  // --- HÀM DUYỆT BÀI (Đã thêm thông báo) ---
  Future<void> approvePost(Map<String, dynamic> post, String adminId) async {
    String postId = post['id'];
    String sellerId = post['sellerId'];
    String category = post['category'] ?? 'Khác';
    String postTitle = post['title'] ?? "Bài đăng";

    Map<String, dynamic> updateData = {};

    Map<String, dynamic> approvedPost = {
      ...post,
      'status': 'approved',
      'approvedBy': adminId,
      'approvedAt': ServerValue.timestamp,
    };

    // 1. Lưu vào mục posted công khai theo danh mục
    updateData["posted/$category/$postId"] = approvedPost;
    
    // 2. Lưu vào kho đồ người dùng theo danh mục
    updateData["user_posts/$sellerId/$category/$postId"] = approvedPost;
    
    // 3. Xóa khỏi hàng chờ posts
    updateData["posts/$postId"] = null;
    
    // 4. Lưu log Admin
    updateData["admin_logs/$adminId/Approved/$category/$postId"] = ServerValue.timestamp;

    // --- MỚI: GỬI THÔNG BÁO CHO USER ---
    String notifId = _dbRef.child("notifications/$sellerId").push().key ?? postId;
    updateData["notifications/$sellerId/$notifId"] = {
      "type": "post_approved",
      "title": "Duyệt bài thành công",
      "content": "Chúc mừng! Bài đăng '$postTitle' của bạn đã được duyệt thành công.",
      "timestamp": ServerValue.timestamp,
      "isRead": false,
      "tabIndex": 1 // Tab "Đã đăng" trong ManagePostsScreen
    };

    await _dbRef.update(updateData);
  }

  Future<void> rejectPost(Map<String, dynamic> post, String adminId, String reason) async {
    // Đảm bảo lấy đúng ID, nếu không có thì dừng lại để tránh crash
    String? postId = post['id'];
    String? sellerId = post['sellerId'];
    
    if (postId == null || sellerId == null) {
      debugPrint("Lỗi: Không tìm thấy ID bài viết hoặc người bán");
      return;
    }

    String category = post['category'] ?? 'Khác';
    String postTitle = post['title'] ?? "Bài đăng";
    String finalReason = reason.trim().isEmpty ? "Không có lý do cụ thể" : reason.trim();

    Map<String, dynamic> updateData = {};

    Map<String, dynamic> refusedPost = {
      ...post,
      'status': 'refused',
      'rejectReason': finalReason,
      'rejectedBy': adminId,
      'rejectedAt': ServerValue.timestamp,
    };

    // Sử dụng đường dẫn an toàn
    updateData["posts/$postId"] = refusedPost;
    updateData["user_posts/$sellerId/$category/$postId"] = refusedPost;
    updateData["admin_logs/$adminId/Refuse/$category/$postId"] = ServerValue.timestamp;

    // Tạo ID thông báo an toàn
    String notifKey = FirebaseDatabase.instance.ref().child("notifications/$sellerId").push().key ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    updateData["notifications/$sellerId/$notifKey"] = {
      "type": "post_refused",
      "title": "Từ chối bài đăng",
      "content": "Bài đăng '$postTitle' bị từ chối. Lý do: $finalReason",
      "timestamp": ServerValue.timestamp,
      "isRead": false,
      "tabIndex": 2 
    };

    try {
      // Kiểm tra dữ liệu trong console trước khi gửi
      debugPrint("Đang cập nhật dữ liệu từ chối cho bài: $postId");
      
      await FirebaseDatabase.instance.ref().update(updateData);

      // Tăng biến đếm
      DatabaseReference countRef = FirebaseDatabase.instance.ref("users/$sellerId/rejectedCount");
      await countRef.runTransaction((Object? postCount) {
        if (postCount == null) return Transaction.success(1);
        return Transaction.success((postCount as int) + 1);
      });

    } catch (e) {
      debugPrint("Lỗi Firebase Update: $e");
      rethrow;
    }
  }

  Stream<DatabaseEvent> getAdminLogStream(String adminId, String logType) {
    return _dbRef.child("admin_logs").child(adminId).child(logType).onValue;
  }
}