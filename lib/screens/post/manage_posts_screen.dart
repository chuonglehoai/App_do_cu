import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/screens/profile_screen.dart' show ProfileScreen;
import 'package:app_do_cu/widgets/custom_bottom_nav.dart' show CustomBottomNav;
import 'package:app_do_cu/widgets/post_tab.dart' show PostTabContent;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; 
import 'package:firebase_database/firebase_database.dart';
import 'add_post_screen.dart';

class ManagePostsScreen extends StatefulWidget {
  final int initialTabIndex;
  const ManagePostsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this, 
      initialIndex: widget.initialTabIndex // Sử dụng tham số ở đây
    );
  }

  
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3E8B98);
    final userId = context.read<UserProvider>().userId ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Quản lý bài đăng', style: GoogleFonts.beVietnamPro(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: "Đang chờ"),
            Tab(text: "Đã đăng"),
            Tab(text: "Bị từ chối"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PostTabContent(stream: _dbRef.child("posts").onValue, targetStatus: "pending", userId: userId),
          PostTabContent(stream: _dbRef.child("posted").onValue, targetStatus: "approved", isPostedNode: true, userId: userId),
          PostTabContent(stream: _dbRef.child("posts").onValue, targetStatus: "refused", userId: userId),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final userId = context.read<UserProvider>().userId;
          if (userId == null || userId.isEmpty) return;

          // 1. Hiển thị loading để ngăn người dùng bấm nhiều lần
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          try {
            // 2. Kiểm tra địa chỉ từ Firebase
            final snapshot = await _dbRef.child("users/$userId/address").get();

            if (!mounted) return;
            Navigator.pop(context); // Đóng loading dialog ngay lập tức

            final address = snapshot.value?.toString().trim();

            // 3. Nếu địa chỉ trống hoặc null
            if (address == null || address.isEmpty) {
              // Hiển thị Dialog thông báo thay vì SnackBar để tránh lỗi mất context
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Yêu cầu cập nhật"),
                  content: const Text("Bạn cần cập nhật địa chỉ hoặc trường học để có thể đăng tin rao vặt."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Để sau"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      onPressed: () {
                        Navigator.pop(ctx); // Đóng Dialog thông báo
                        // Sử dụng MaterialPageRoute để tránh lỗi trắng màn hình do thiếu Route Name
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: const Text("Cập nhật ngay", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            } else {
              // Đã có địa chỉ -> Chuyển sang màn hình đăng bài
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPostScreen()),
              );
            }
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context); // Đóng loading nếu gặp lỗi kết nối
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Không thể kiểm tra thông tin: $e")),
            );
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}