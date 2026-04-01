import 'package:firebase_database/firebase_database.dart';

class AdminService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getPendingPostsStream() {
    return _dbRef.child("posts").onValue;
  }

  // --- HÀM DUYỆT BÀI ---
  Future<void> approvePost(Map<String, dynamic> post, String adminId) async {
    String postId = post['id'];
    String sellerId = post['sellerId'];
    String category = post['category'] ?? 'Khác';

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
    
    // 4. Lưu log Admin: admin_logs/Approved/tên danh mục/id bài đăng
    updateData["admin_logs/$adminId/Approved/$category/$postId"] = ServerValue.timestamp;

    await _dbRef.update(updateData);
  }

  // --- HÀM TỪ CHỐI BÀI ---
  Future<void> rejectPost(Map<String, dynamic> post, String adminId, String reason) async {
    String postId = post['id'];
    String sellerId = post['sellerId'];
    String category = post['category'] ?? 'Khác';
    
    Map<String, dynamic> updateData = {};

    Map<String, dynamic> refusedPost = {
      ...post,
      'status': 'refused',
      'rejectReason': reason,
      'rejectedBy': adminId,
      'rejectedAt': ServerValue.timestamp,
    };

    // 1. Cập nhật trạng thái trong node posts để admin/user vẫn thấy bài gốc
    updateData["posts/$postId"] = refusedPost;

    // 2. Lưu vào kho đồ người dùng (mục bị từ chối) theo danh mục
    updateData["user_posts/$sellerId/$category/$postId"] = refusedPost;

    // 3. Lưu log Admin: admin_logs/Refuse/tên danh mục/id bài đăng
    updateData["admin_logs/$adminId/Refuse/$category/$postId"] = ServerValue.timestamp;

    await _dbRef.update(updateData);
  }

  // Hàm lấy Log Admin phân cấp theo tab
  Stream<DatabaseEvent> getAdminLogStream(String adminId, String logType) {
    // logType: "Approved" hoặc "Refuse"
    return _dbRef.child("admin_logs").child(adminId).child(logType).onValue;
  }
}