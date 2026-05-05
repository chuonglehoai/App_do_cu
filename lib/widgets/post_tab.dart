import 'package:app_do_cu/models/product_model.dart' show Product;
import 'package:app_do_cu/screens/post/add_post_screen.dart' show AddPostScreen;
import 'package:firebase_database/firebase_database.dart' show DatabaseEvent, FirebaseDatabase, DatabaseReference, Transaction;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show StatefulWidget, AutomaticKeepAliveClientMixin, State, BuildContext, Widget, Center, EdgeInsets, Text, ConnectionState, CircularProgressIndicator, ListView, StreamBuilder, Container, SizedBox, TextStyle, Divider, Colors, BorderRadius, BoxShadow, BoxDecoration, CrossAxisAlignment, Image, BoxFit, ClipRRect, FontWeight, Color, Column, Expanded, Row, showDialog, SnackBar, Navigator, TextButton, AlertDialog, ScaffoldMessenger, IconButton, Icon, Icons, InkWell, BoxConstraints, MaterialPageRoute, TextOverflow;

class PostTabContent extends StatefulWidget {
  final Stream<DatabaseEvent> stream;
  final String targetStatus;
  final bool isPostedNode;
  final String userId;

  const PostTabContent({
    super.key,
    required this.stream,
    required this.targetStatus,
    this.isPostedNode = false,
    required this.userId,
  });

  @override
  State<PostTabContent> createState() => _PostTabContentState();
}

// Thêm AutomaticKeepAliveClientMixin ở đây
class _PostTabContentState extends State<PostTabContent> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Trả về true để giữ trạng thái
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(); // Tham chiếu gốc

  Future<void> _deletePost(String postId, bool isPostedNode, Map<String, dynamic> postData) async {
    // 1. Xác nhận xóa
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa bài đăng này không? Dữ liệu sẽ không thể khôi phục."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Xóa", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      // Lấy thông tin cần thiết từ postData truyền vào
      String sellerId = postData['sellerId'] ?? "";
      String category = postData['category'] ?? "Khác";
      String status = postData['status'] ?? "";

      Map<String, dynamic> updates = {};

      // 2. Xóa tại node chính (posts hoặc posted)
      if (isPostedNode) {
        // Vì node 'posted' phân cấp theo Category nên xóa trực tiếp nếu đã biết Category
        updates["posted/$category/$postId"] = null;
      } else {
        // Node 'posts' của bạn lưu phẳng hoặc theo cấu trúc riêng
        updates["posts/$category/$postId"] = null;
      }

      // 3. Xóa tại node 'user_posts' (Cấu trúc: user_posts/uid/category/postId)
      updates["user_posts/$sellerId/$category/$postId"] = null;

      // THỰC HIỆN XÓA ĐỒNG LOẠT
      await _dbRef.update(updates);

      // 4. CẬP NHẬT BIẾN ĐẾM (Nếu bài bị xóa là bài đang bị từ chối)
      if (status == 'refused' && sellerId.isNotEmpty) {
        DatabaseReference countRef = FirebaseDatabase.instance.ref("users/$sellerId/rejectedCount");
        await countRef.runTransaction((Object? postCount) {
          if (postCount == null || (postCount as int) <= 0) {
            return Transaction.success(0);
          }
          return Transaction.success((postCount as int) - 1);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa bài đăng và cập nhật thống kê thành công"))
        );
      }
    } catch (e) {
      debugPrint("Lỗi xóa bài: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi khi xóa bài. Vui lòng thử lại."))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Bắt buộc phải gọi dòng này
    
    return StreamBuilder<DatabaseEvent>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        List<Map<String, dynamic>> displayPosts = [];
        
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value;
          if (data is Map) {
            if (widget.isPostedNode) {
              data.forEach((catName, postsInCat) {
                if (postsInCat is Map) {
                  postsInCat.forEach((postId, postData) {
                    if (postData is Map && postData['sellerId'] == widget.userId) {
                      displayPosts.add({...Map<String, dynamic>.from(postData), 'id': postId});
                    }
                  });
                }
              });
            } else {
              data.forEach((postId, postData) {
                if (postData is Map && 
                    postData['sellerId'] == widget.userId && 
                    postData['status'] == widget.targetStatus) {
                  displayPosts.add({...Map<String, dynamic>.from(postData), 'id': postId});
                }
              });
            }
          }
        }

        if (displayPosts.isEmpty) return const Center(child: Text("Không có bài đăng nào"));

        displayPosts.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: displayPosts.length,
          itemBuilder: (context, index) {
            final post = displayPosts[index];
            // Trong ListView.builder của post_tab.dart
            return InkWell(
              onTap: () {
                // Chuyển đổi Map dữ liệu từ Firebase sang Model Product
                // 'post' ở đây là Map<String, dynamic> bạn lấy từ snapshot
                final productToEdit = Product.fromMap(post, post['id']);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPostScreen(
                      product: productToEdit,
                      // Nếu bài đã đăng (approved), bạn có thể truyền isReadOnly: true nếu muốn
                      isReadOnly: widget.targetStatus == "approved", 
                    ),
                  ),
                );
              },
              child: _buildPostCard(
                postFullData: post,
                postId: post['id'],
                title: post['title'] ?? "Không tiêu đề",
                price: "${post['price'] ?? 0}đ",
                status: post['status'] ?? "",
                imageUrl: (post['images'] != null && (post['images'] as List).isNotEmpty) 
                    ? post['images'][0] 
                    : "https://via.placeholder.com/100",
                reason: post['rejectReason'],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostCard({
    required Map<String, dynamic> postFullData,
    required String postId,
    required String title,
    required String price,
    required String status,
    required String imageUrl,
    String? reason,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Căn trên để tiêu đề đẹp hơn
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(price,
                        style: const TextStyle(color: Color(0xFF3E8B98), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _buildStatusChip(status),
                  ],
                ),
              ),
              // NÚT XÓA: Để ở đây sẽ nằm gọn bên phải thẻ
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                onPressed: () => _deletePost(postId, widget.isPostedNode,postFullData),
              ),
            ],
          ),
          if (status == 'refused' && reason != null) ...[
            const Divider(),
            Text(
              "Lý do từ chối: $reason",
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ]
        ],
      ),
    );
  }
  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending': color = Colors.orange; text = "Chờ duyệt"; break;
      case 'approved': color = Colors.green; text = "Đã đăng"; break;
      case 'refused': color = Colors.red; text = "Bị từ chối"; break;
      default: color = Colors.grey; text = "Không xác định";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
  
}