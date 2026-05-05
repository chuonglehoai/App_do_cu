
import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/screens/post/manage_posts_screen.dart';
import 'package:app_do_cu/widgets/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:app_do_cu/services/database_profile.dart';
import 'package:app_do_cu/showError.dart';
import '../services/profile_service.dart'; // Import file controller

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ProfileService {
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF3E8B98);
    const Color backgroundLight = Color(0xFFF6F7F7);
    const Color warningGold = Color(0xFFFFAB40);

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        title: Text('Thông tin cá nhân', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildProfileHeader(primaryColor),
                const SizedBox(height: 24),
                _buildWarningPanel(warningGold, primaryColor),
                const SizedBox(height: 24),
                _buildSectionHeader('Quản lý hoạt động'),
                _buildActionGroup([
                    _buildListItem(
                      icon: Icons.grid_view, 
                      label: 'Bài đăng của tôi', 
                      iconColor: primaryColor, 
                      bgColor: primaryColor.withOpacity(0.1),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePostsScreen(initialTabIndex: 1))),
                    )
                  ]
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Cài đặt'),
                _buildActionGroup([
                  _buildListItem(
                    icon: Icons.edit, 
                    label: 'Chỉnh sửa thông tin', 
                    iconColor: Colors.blue, 
                    bgColor: Colors.blue.withOpacity(0.1),
                    onTap: showUpdateDialog,
                  ),
                  _buildListItem(
                    icon: Icons.logout, 
                    label: 'Đăng xuất', 
                    iconColor: Colors.red, 
                    bgColor: Colors.red.withOpacity(0.1), 
                    isLogout: true,
                    onTap: handleLogout,
                  ),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
    );
  }

  Widget _buildProfileHeader(Color primaryColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: (userData['avatarUrl'] != null && userData['avatarUrl'].isNotEmpty)
                  ? NetworkImage(userData['avatarUrl'])
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            IconButton(
              onPressed: handleUpdateAvatar,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(userData['fullName'] ?? 'Chưa cập nhật tên', style: GoogleFonts.beVietnamPro(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('MSSV: ${userData['studentId'] ?? 'Chưa có MSSV'}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(userData['school'] ?? userData['address'] ?? 'Chưa cập nhật trường', style: GoogleFonts.beVietnamPro(color: Colors.grey)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(userData['phone'] ?? 'Chưa có SĐT', style: GoogleFonts.beVietnamPro(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildWarningPanel(Color warningGold, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warningGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.report, color: warningGold, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tình trạng tài khoản', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  StreamBuilder<DatabaseEvent>(
                    stream: FirebaseDatabase.instance.ref("users/${context.read<UserProvider>().userId}/rejectedCount").onValue,
                    builder: (context, snapshot) {
                      int count = 0;
                      if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                        count = int.parse(snapshot.data!.snapshot.value.toString());
                      }
                      return Text.rich(
                        TextSpan(
                          text: 'Số bài đăng bị từ chối: ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          children: [
                            TextSpan(text: '$count', style: TextStyle(color: warningGold)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ManagePostsScreen(initialTabIndex: 2))
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Chi tiết', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: primaryColor, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildActionGroup(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(children: children),
      ),
    );
  }
  
  Widget _buildListItem({required IconData icon, required String label, required Color iconColor, required Color bgColor, bool isLogout = false, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor)),
          title: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isLogout ? Colors.red : const Color(0xFF131616))),
          trailing: isLogout ? null : const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLogout) Divider(height: 1, indent: 64, color: Colors.grey.shade100),
      ],
    );
  }
}