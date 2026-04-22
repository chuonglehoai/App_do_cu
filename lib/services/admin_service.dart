import 'package:firebase_database/firebase_database.dart';

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

  // --- HÀM TỪ CHỐI BÀI (Đã thêm thông báo) ---
  Future<void> rejectPost(Map<String, dynamic> post, String adminId, String reason) async {
    String postId = post['id'];
    String sellerId = post['sellerId'];
    String category = post['category'] ?? 'Khác';
    String postTitle = post['title'] ?? "Bài đăng";
    
    Map<String, dynamic> updateData = {};

    Map<String, dynamic> refusedPost = {
      ...post,
      'status': 'refused',
      'rejectReason': reason,
      'rejectedBy': adminId,
      'rejectedAt': ServerValue.timestamp,
    };

    // 1. Cập nhật trạng thái trong node posts
    updateData["posts/$postId"] = refusedPost;

    // 2. Lưu vào kho đồ người dùng
    updateData["user_posts/$sellerId/$category/$postId"] = refusedPost;

    // 3. Lưu log Admin
    updateData["admin_logs/$adminId/Refuse/$category/$postId"] = ServerValue.timestamp;

    // --- MỚI: GỬI THÔNG BÁO CHO USER ---
    String notifId = _dbRef.child("notifications/$sellerId").push().key ?? postId;
    updateData["notifications/$sellerId/$notifId"] = {
      "type": "post_refused",
      "title": "Từ chối bài đăng",
      "content": "Bài đăng '$postTitle' bị từ chối. Lý do: $reason",
      "timestamp": ServerValue.timestamp,
      "isRead": false,
      "tabIndex": 2 // Tab "Bị từ chối" trong ManagePostsScreen
    };

    await _dbRef.update(updateData);
  }

  Stream<DatabaseEvent> getAdminLogStream(String adminId, String logType) {
    return _dbRef.child("admin_logs").child(adminId).child(logType).onValue;
  }
}