import 'package:app_do_cu/screens/ProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; 
import 'package:app_do_cu/services/database_product.dart';
import 'add_post_screen.dart'; //
import 'home_screen.dart'; //

class ManagePostsScreen extends StatefulWidget {
  const ManagePostsScreen({super.key});

  @override
  State<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseProduct _dbService = DatabaseProduct();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3E8B98);
    const Color backgroundLight = Color(0xFFF6F7F7);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF131616), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Quản lý bài đăng', 
          style: GoogleFonts.beVietnamPro(color: const Color(0xFF131616), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Đang chờ'),
            Tab(text: 'Đã đăng'),
            Tab(text: 'Bị từ chối'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(status: 'pending'),
          _buildPostList(status: 'published'),
          _buildPostList(status: 'rejected'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddPostScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Hàm build danh sách (Giao diện lặp lại)
  Widget _buildPostList({required String status}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Sau này thay bằng list thực tế từ Service
      itemBuilder: (context, index) {
        if (status == 'rejected') return _buildRejectedCard();
        return _buildNormalCard(status);
      },
    );
  }

  Widget _buildNormalCard(String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tên sản phẩm mẫu', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('Hôm nay, 10:45', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3E8B98))),
              ],
            ),
          ),
          const Icon(Icons.edit_square, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildRejectedCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.1))),
      child: Column(
        children: [
          const Row(children: [ /* Tương tự card trên nhưng màu xám */ ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.red.withOpacity(0.05),
            child: const Text('Lý do: Hình ảnh mờ...', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }
  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF3E8B98),
      currentIndex: 2,
      onTap: (index) {
      // Xử lý chuyển màn hình dựa trên index
        switch (index) {
          case 0:
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const HomeScreen())
            );
            break;
          case 1:
            // Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
            break;
          case 2:
            break;
          case 4:
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const ProfileScreen())
            );
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Tin nhắn'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Kho đồ'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Thông báo'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
      ],
    );
  }
}