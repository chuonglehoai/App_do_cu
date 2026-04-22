import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/screens/ProfileScreen.dart';
import 'package:app_do_cu/widgets/custom_bottom_nav.dart' show CustomBottomNav;
import 'package:app_do_cu/widgets/post_tab.dart' show PostTabContent;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; 
import 'package:firebase_database/firebase_database.dart';
import 'add_post_screen.dart';
import 'home_screen.dart';

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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPostScreen())),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}