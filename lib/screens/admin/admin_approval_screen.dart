import 'package:app_do_cu/screens/admin/admin_settings_screen.dart' show AdminSettingsScreen;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../../UserProvider.dart';
import '../../services/admin/admin_approval_service.dart'; // Import controller

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends AdminApprovalService {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: bottomNavIndex == 0 ? _buildHeader() : null,
      body: bottomNavIndex == 0 
          ? _buildMainAdminBody() 
          : const AdminSettingsScreen(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMainAdminBody() {
    final String adminId = context.read<UserProvider>().userId ?? "";
    return Column(
      children: [
        _buildFilterTabs(),
        Expanded(
          child: currentTabIndex == 0 
            ? _buildPendingList() 
            : _buildLogList(adminId),
        ),
      ],
    );
  }

  Widget _buildPendingList() {
    return StreamBuilder<DatabaseEvent>(
      stream: adminService.getPendingPostsStream(),
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

  Widget _buildLogList(String adminId) {
    String logType = currentTabIndex == 1 ? "Approved" : "Refuse";
    return StreamBuilder<DatabaseEvent>(
      stream: adminService.getAdminLogStream(adminId, logType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(child: Text("Bạn chưa xử lý bài nào ở mục này"));
        }

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
              future: getPostDetailById(postIds[index]),
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

  Widget _buildPostCard(Map<String, dynamic> post) {
    final String adminId = context.read<UserProvider>().userId ?? "";
    String imageUrl = (post['images'] != null && (post['images'] as List).isNotEmpty) 
        ? post['images'][0] : "https://via.placeholder.com/400x300";

    return GestureDetector(
      onTap: () => goToPostDetail(post), // Nhấn để xem chi tiết
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                      FutureBuilder<String>(
                        future: getSellerName(post['sellerId']),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? post['sellerName'] ?? "Người dùng", 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                          );
                        },
                      ),
                      Text(post['category'] ?? "Khác", 
                        style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(post['title'] ?? "", style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("${post['price']}đ", 
                    style: TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.bold)),
                  
                  // Chỉ hiện nút Duyệt/Từ chối ở Tab "Chờ duyệt"
                  if (currentTabIndex == 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => showRejectDialog(post),
                            child: const Text("Từ chối", style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => adminService.approvePost(post, adminId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Duyệt tin", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      title: Column(
        children: [
          Text('Hệ thống Quản lý', style: GoogleFonts.beVietnamPro(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(currentTabIndex == 0 ? 'DUYỆT TIN' : 'LỊCH SỬ XỬ LÝ', 
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
    bool isActive = currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentTabIndex = index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? primaryColor : Colors.transparent, width: 3))),
          child: Text(label, style: GoogleFonts.beVietnamPro(color: isActive ? primaryColor : greyText, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryColor,
      currentIndex: bottomNavIndex,
      onTap: (index) => setState(() => bottomNavIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: "Duyệt tin"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Cài đặt"),
      ],
    );
  }
}