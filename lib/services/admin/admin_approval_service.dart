import 'package:app_do_cu/models/product_model.dart' show Product;
import 'package:app_do_cu/screens/post/product_detail_screen.dart' show ProductDetailScreen;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:provider/provider.dart';
import '../../UserProvider.dart';
import 'admin_service.dart';
import '../../screens/admin/admin_approval_screen.dart';

abstract class AdminApprovalService extends State<AdminApprovalScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);
  final Color backgroundLight = const Color(0xFFF6F7F7);
  final Color textColor = const Color(0xFF131616);
  final Color greyText = const Color(0xFF6C7C7F);

  final AdminService adminService = AdminService();
  int currentTabIndex = 0; // 0: Chờ duyệt, 1: Đã duyệt, 2: Bị từ chối
  int bottomNavIndex = 0; // 0: Duyệt tin, 1: Cài đặt

  void showRejectDialog(Map<String, dynamic> postData) {
    TextEditingController reasonController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 12, left: 20, right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            Text("Từ chối bài đăng", style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Text("Vui lòng cung cấp lý do cụ thể để người dùng có thể chỉnh sửa lại bài đăng.", style: TextStyle(color: greyText, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Ví dụ: Hình ảnh mờ, giá không hợp lệ...",
                filled: true,
                fillColor: backgroundLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Hủy", style: TextStyle(color: greyText)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (reasonController.text.trim().isNotEmpty) {
                        final String adminId = context.read<UserProvider>().userId ?? "";
                        await adminService.rejectPost(postData, adminId, reasonController.text.trim());
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text("Xác nhận từ chối", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<Map<String, dynamic>?> getPostDetailById(String postId) async {
    final postSnap = await FirebaseDatabase.instance.ref("posts/$postId").get();
    if (postSnap.exists) return Map<String, dynamic>.from(postSnap.value as Map);

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

  Future<String> getSellerName(String? sellerId) async {
    if (sellerId == null || sellerId.isEmpty) return "Người dùng";
    try {
      final snapshot = await FirebaseDatabase.instance.ref("users/$sellerId/fullName").get();
      if (snapshot.exists) {
        return snapshot.value.toString();
      }
    } catch (e) {
      debugPrint("Lỗi lấy tên người bán: $e");
    }
    return "Người dùng";
  }

  void goToPostDetail(Map<String, dynamic> postData) {
    final product = Product.fromMap(postData, postData['id'] ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: product, 
          isAdminView: currentTabIndex == 0,
        ),
      ),
    );
  }
}