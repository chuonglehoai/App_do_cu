import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import các widget bạn đã tách ra file riêng
import '../widgets/search_bar_widget.dart';
import '../widgets/category_item.dart';
import '../widgets/product_card.dart';
import 'ProfileScreen.dart';
import 'ManagePostsScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: _buildHeader(),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CustomSearchBar(hintText: 'Tìm giáo trình...'),
          ),
          _buildCategorySection(),
          _buildProductSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // --- Header giữ nguyên vì nó đặc thù cho trang này ---
  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          const CircleAvatar(
            radius: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHÀO BUỔI SÁNG',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3E8B98),
                      letterSpacing: 1.2)),
              Text('Khám phá đồ cũ',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- Gom nhóm Danh mục dùng CategoryItem ---
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('DANH MỤC PHỔ BIẾN',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
        ),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              CategoryItem(icon: Icons.bolt, label: 'Đồ điện', isPrimary: true),
              SizedBox(width: 16),
              CategoryItem(icon: Icons.menu_book, label: 'Học tập'),
              SizedBox(width: 16),
              CategoryItem(icon: Icons.sports_basketball, label: 'Thể thao'),
              SizedBox(width: 16),
              CategoryItem(icon: Icons.chair, label: 'Nội thất'),
              SizedBox(width: 16),
              CategoryItem(icon: Icons.more_horiz, label: 'Khác'),
            ],
          ),
        ),
      ],
    );
  }

  // --- Gom nhóm Sản phẩm dùng ProductCard ---
  Widget _buildProductSection() {
    // Giả lập dữ liệu từ Database/Firebase
    final products = [
      {
        'title': 'Nồi cơm điện mini Sharp',
        'loc': 'KTX Khu B',
        'price': '150.000đ',
        'tag': 'BÁN RẺ',
        'tagCol': const Color(0xFF3E8B98)
      },
      {
        'title': 'Giáo trình Kinh tế vi mô',
        'loc': 'ĐH Kinh tế',
        'price': 'Miễn phí',
        'tag': 'TẶNG',
        'tagCol': const Color(0xFF6BBF59)
      },
      {
        'title': 'Vợt cầu lông Yonex cũ',
        'loc': 'Q. Thủ Đức',
        'price': 'Đổi đồ dùng',
        'tag': 'TRAO ĐỔI',
        'tagCol': const Color(0xFFFFAB40)
      },
      {
        'title': 'Đèn bàn học chống cận',
        'loc': 'KTX Khu A',
        'price': '80.000đ',
        'tag': 'BÁN RẺ',
        'tagCol': const Color(0xFF3E8B98)
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sản phẩm mới duyệt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('XEM TẤT CẢ',
                    style: TextStyle(color: Color(0xFF3E8B98), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              // Gọi Widget ProductCard đã tách
              return ProductCard(
                title: p['title'] as String,
                location: p['loc'] as String,
                price: p['price'] as String,
                tag: p['tag'] as String,
                tagColor: p['tagCol'] as Color,
                imageUrl: 'https://via.placeholder.com/300x200',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF3E8B98),
      currentIndex: 0,
      onTap: (index) {
      // Xử lý chuyển màn hình dựa trên index
        switch (index) {
          case 0:
            // Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
            break;
          case 1:
            // Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen()));
            break;
          case 2:
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const ManagePostsScreen())
            );
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