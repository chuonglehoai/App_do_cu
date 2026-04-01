import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/screens/ProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; 
import 'package:firebase_database/firebase_database.dart';
import 'add_post_screen.dart';
import 'home_screen.dart';

class ManagePostsScreen extends StatefulWidget {
  const ManagePostsScreen({super.key});

  @override
  State<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // Widget hiển thị danh sách bài đăng dựa trên Stream
  Widget _buildPostListStream(Stream<DatabaseEvent> stream, String targetStatus, {bool isPostedNode = false}) {
  final userId = context.read<UserProvider>().userId;

  return StreamBuilder<DatabaseEvent>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

      List<Map<String, dynamic>> displayPosts = [];
      
      // KIỂM TRA AN TOÀN: snapshot.data và snapshot.data.snapshot.value không được Null
      if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
        final data = snapshot.data!.snapshot.value;
        
        if (data is Map) { // Đảm bảo dữ liệu trả về là một Map
          if (isPostedNode) {
            // Mục "Đã đăng": Duyệt qua các danh mục
            data.forEach((catName, postsInCat) {
              if (postsInCat is Map) {
                postsInCat.forEach((postId, postData) {
                  if (postData is Map && postData['sellerId'] == userId) {
                    displayPosts.add({...Map<String, dynamic>.from(postData), 'id': postId});
                  }
                });
              }
            });
          } else {
            // Mục "Đang chờ" & "Bị từ chối"
            data.forEach((postId, postData) {
              if (postData is Map && 
                  postData['sellerId'] == userId && 
                  postData['status'] == targetStatus) {
                displayPosts.add({...Map<String, dynamic>.from(postData), 'id': postId});
              }
            });
          }
        }
      }

      if (displayPosts.isEmpty) {
        return const Center(child: Text("Không có bài đăng nào"));
      }

      // Sắp xếp theo thời gian mới nhất
      displayPosts.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayPosts.length,
        itemBuilder: (context, index) {
          final post = displayPosts[index];
          return _buildPostCard(
            title: post['title'] ?? "Không tiêu đề",
            price: "${post['price'] ?? 0}đ",
            status: post['status'] ?? "",
            // Kiểm tra list images an toàn
            imageUrl: (post['images'] != null && (post['images'] as List).isNotEmpty) 
                ? post['images'][0] 
                : "https://via.placeholder.com/100",
            reason: post['rejectReason'], // Sẽ là null nếu không phải mục Bị từ chối
          );
        },
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3E8B98);

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
          // Mục 1: Đang chờ (status: pending trong posts)
          _buildPostListStream(_dbRef.child("posts").onValue, "pending"),
          // Mục 2: Đã đăng (trong node posted)
          _buildPostListStream(_dbRef.child("posted").onValue, "approved", isPostedNode: true),
          // Mục 3: Bị từ chối (status: refused trong posts)
          _buildPostListStream(_dbRef.child("posts").onValue, "refused"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPostScreen())),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildPostCard({required String title, required String price, required String status, required String imageUrl, String? reason}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(price, style: const TextStyle(color: Color(0xFF3E8B98), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _buildStatusChip(status),
                  ],
                ),
              ),
            ],
          ),
          if (status == 'refused' && reason != null) ...[
            const Divider(),
            Text("Lý do từ chối: $reason", style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
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

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF3E8B98),
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        if (index == 4) Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
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