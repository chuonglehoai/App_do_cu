import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../UserProvider.dart';
import '../services/admin_service.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);
  final Color backgroundLight = const Color(0xFFF6F7F7);
  final Color textColor = const Color(0xFF131616);
  final Color greyText = const Color(0xFF6C7C7F);

  final AdminService _adminService = AdminService();
  int _currentTabIndex = 0; // 0: Chờ duyệt, 1: Đã duyệt, 2: Bị từ chối

  // Hàm hiển thị hộp thoại từ chối với lý do
  void _showRejectDialog(Map<String, dynamic> postData) {
    TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Lý do từ chối"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Nhập lý do tại đây..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                final String adminId = context.read<UserProvider>().userId ?? "";
                // Thực hiện từ chối bài và ghi log phân cấp
                await _adminService.rejectPost(postData, adminId, reasonController.text.trim());
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Gửi"),
          ),
        ],
      ),
    );
  }

  // Hàm tìm kiếm chi tiết bài đăng từ ID trong các node khác nhau
  Future<Map<String, dynamic>?> _getPostDetailById(String postId) async {
    // 1. Tìm trong posts (cho tin chờ duyệt hoặc mới bị từ chối)
    final postSnap = await FirebaseDatabase.instance.ref("posts/$postId").get();
    if (postSnap.exists) return Map<String, dynamic>.from(postSnap.value as Map);

    // 2. Tìm trong posted (duyệt qua các danh mục)
    final postedSnap = await FirebaseDatabase.instance.ref("posted").get();
    if (postedSnap.exists) {
      Map<dynamic, dynamic> categories = postedSnap.value as Map;
      for (var cat in categories.values) {
        if (cat is Map && cat.containsKey(postId)) {
          return Map<String, dynamic>.from(cat[postId]);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String adminId = context.read<UserProvider>().userId ?? "";

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: _buildHeader(),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _currentTabIndex == 0 
              ? _buildPendingList() 
              : _buildLogList(adminId),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- TAB 1: DANH SÁCH CHỜ DUYỆT (Realtime) ---
  Widget _buildPendingList() {
    return StreamBuilder<DatabaseEvent>(
      stream: _adminService.getPendingPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        List<Map<String, dynamic>> posts = [];
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          data.forEach((key, value) {
            if (value['status'] == 'pending') {
              posts.add({...Map<String, dynamic>.from(value), 'id': key});
            }
          });
        }

        if (posts.isEmpty) return const Center(child: Text("Không có tin nào đang chờ duyệt"));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(posts[index]),
        );
      },
    );
  }

  // --- TAB 2 & 3: LỊCH SỬ DUYỆT (Lấy ID từ admin_logs -> Truy chi tiết) ---
  Widget _buildLogList(String adminId) {
    String logType = _currentTabIndex == 1 ? "Approved" : "Refuse";
    
    return StreamBuilder<DatabaseEvent>(
      stream: _adminService.getAdminLogStream(adminId, logType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(child: Text("Bạn chưa có bài nào ở mục $logType"));
        }

        // Duyệt log phân cấp: admin_logs -> AdminID -> Approved/Refuse -> Category -> PostID
        Map<dynamic, dynamic> categoriesLog = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
        List<String> postIds = [];
        categoriesLog.forEach((cat, posts) {
          if (posts is Map) postIds.addAll(posts.keys.cast<String>());
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: postIds.length,
          itemBuilder: (context, index) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: _getPostDetailById(postIds[index]),
              builder: (context, postSnap) {
                if (!postSnap.hasData || postSnap.data == null) return const SizedBox.shrink();
                return _buildPostCard({...postSnap.data!, 'id': postIds[index]});
              },
            );
          },
        );
      },
    );
  }

  // --- WIDGET GIAO DIỆN CARD BÀI ĐĂNG ---
  Widget _buildPostCard(Map<String, dynamic> post) {
    final String adminId = context.read<UserProvider>().userId ?? "";
    String imageUrl = (post['images'] != null && (post['images'] as List).isNotEmpty) 
        ? post['images'][0] : "https://via.placeholder.com/400x300";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(post['sellerName'] ?? "Người dùng", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(post['category'] ?? "Khác", style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(post['title'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${post['price']}đ", style: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(post['description'] ?? "", maxLines: 2, style: TextStyle(color: greyText, fontSize: 13)),
                
                if (_currentTabIndex == 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRejectDialog(post),
                          child: const Text("Từ chối"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _adminService.approvePost(post, adminId),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                          child: const Text("Duyệt tin", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  )
                ] else if (_currentTabIndex == 2 && post['rejectReason'] != null) ...[
                  const Divider(),
                  Text("Lý do từ chối: ${post['rejectReason']}", style: const TextStyle(color: Colors.red, fontSize: 12)),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- CÁC WIDGET GIAO DIỆN PHỤ (Header, Tabs, Nav) ---
  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          Text('Hệ thống Quản lý', style: GoogleFonts.beVietnamPro(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(_currentTabIndex == 0 ? 'DUYỆT TIN' : 'LỊCH SỬ XỬ LÝ', 
               style: GoogleFonts.beVietnamPro(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildTabItem("Chờ duyệt", 0),
          _buildTabItem("Đã duyệt", 1),
          _buildTabItem("Bị từ chối", 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    bool isActive = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? primaryColor : Colors.transparent, width: 3))),
          child: Text(label, style: GoogleFonts.beVietnamPro(color: isActive ? primaryColor : greyText, fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryColor,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: "Duyệt tin"),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: "Thống kê"),
        BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: "Thành viên"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Cài đặt"),
      ],
    );
  }
}