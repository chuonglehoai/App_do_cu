import 'dart:io';

import 'package:app_do_cu/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:app_do_cu/services/database_profile.dart';
import 'package:app_do_cu/showError.dart';
import 'package:app_do_cu/services/cloudinary_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  String? _uploadedUrl;
  final CloudinaryService _imageService = CloudinaryService();
  // Biến lưu trữ thông tin người dùng
  Map<dynamic, dynamic> userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
  final userId = context.read<UserProvider>().userId;
  final data = await _dbService.getUserData(userId!);
  setState(() {
    userData = data ?? {};
    _isLoading = false;
  });
}
  Future<void> _handleUpdateAvatar() async {
    setState(() => _isLoading = true);
  final userId = context.read<UserProvider>().userId;
  File? _selectedImage;
  String? newUrl = await _dbService.uploadAndSaveAvatar(userId!); 
  
  if (newUrl != null) {
    await _loadData(); // Tải lại UI sau khi thành công
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green),
    );
  }
  
  setState(() => _isLoading = false);
  }


  // --- Hàm Đăng xuất ---
  Future<void> _handleLogout() async {
    Provider.of<UserProvider>(context, listen: false).setUserId("");
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // --- Popup Cập nhật thông tin ---
  void _showUpdateDialog() {
    final nameController = TextEditingController(text: userData['fullName']);
    final phoneController = TextEditingController(text: userData['phone'] ?? '');
    final addressController = TextEditingController(text: userData['address'] ?? '');
    final studentIdController = TextEditingController(text: userData['studentId'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ và tên')),
              TextField(controller: studentIdController, decoration: const InputDecoration(labelText: 'Mã số sinh viên')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Địa chỉ/Trường')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          // Trong _showUpdateDialog...
          ElevatedButton(
            onPressed: () async {
              // 1. Lấy userId từ Provider
              final userId = Provider.of<UserProvider>(context, listen: false).userId;
              
              if (userId != null) {
                // 2. Gọi hàm cập nhật từ file bên ngoài
                // Giả sử hàm của bạn nằm trong class DatabaseService
                bool success = await DatabaseService().updateStudentInfo(
                  uid: userId,
                  fullName: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  studentId: studentIdController.text.trim(),
                  school: addressController.text.trim(),
                );

                if (success) {
                  if (!mounted) return;
                  Navigator.pop(context); // Đóng Dialog
                  
                  // 3. Quan trọng: Gọi lại hàm fetch để cập nhật giao diện Profile
                  _loadData(); 
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green),
                  );
                } else {
                  // Xử lý khi có lỗi kết nối hoặc Firebase từ chối
                  context.showError("Cập nhật thất bại!");
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

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
      body: _isLoading 
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
                  _buildListItem(icon: Icons.grid_view, label: 'Bài đăng của tôi', iconColor: primaryColor, bgColor: primaryColor.withOpacity(0.1)),
                  _buildListItem(icon: Icons.favorite, label: 'Sản phẩm yêu thích', iconColor: Colors.pink, bgColor: Colors.pink.withOpacity(0.1)),
                ]),
                const SizedBox(height: 24),
                _buildSectionHeader('Cài đặt'),
                _buildActionGroup([
                  _buildListItem(
                    icon: Icons.edit, 
                    label: 'Chỉnh sửa thông tin', 
                    iconColor: Colors.blue, 
                    bgColor: Colors.blue.withOpacity(0.1),
                    onTap: _showUpdateDialog,
                  ),
                  _buildListItem(
                    icon: Icons.logout, 
                    label: 'Đăng xuất', 
                    iconColor: Colors.red, 
                    bgColor: Colors.red.withOpacity(0.1), 
                    isLogout: true,
                    onTap: _handleLogout,
                  ),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileHeader(Color primaryColor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 128, height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(userData['avatar']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            IconButton(
              onPressed: _handleUpdateAvatar,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.photo_camera, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(userData['fullName'] ?? 'Chưa cập nhật', style: GoogleFonts.beVietnamPro(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('MSSV: ${userData['studentId'] ?? 'N/A'}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(userData['address'] ?? 'Đại học Bách Khoa TP.HCM', style: GoogleFonts.beVietnamPro(color: Colors.grey)),
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

  // --- Widget: Warning Panel ---
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
                  Text.rich(
                    TextSpan(
                      text: 'Số lần cảnh cáo: ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      children: [TextSpan(text: '0', style: TextStyle(color: warningGold))],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text('Chi tiết', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                Icon(Icons.arrow_forward, color: primaryColor, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget: Section Header ---
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

  // --- Widget: List Group Container ---
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
  
  // --- Widget: List Item ---
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