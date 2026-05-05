import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/screens/login_and_regist/forgot_password_screen.dart' show ForgotPasswordScreen;
import 'package:app_do_cu/screens/login_and_regist/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../../services/admin/admin_settings_service.dart'; // Import controller

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends AdminSettingsService {
  @override
  Widget build(BuildContext context) {
    final String adminId = context.read<UserProvider>().userId ?? "";

    return FutureBuilder<DataSnapshot>(
      future: dbRef.child("admins").child(adminId).get(),
      builder: (context, snapshot) {
        String role = "Đang tải...";
        String name = "Admin Manager";
        bool isRoot = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          Map data = snapshot.data!.value as Map;
          role = data['role'] ?? "admin";
          name = data['fullName'] ?? "Admin";
          isRoot = role == 'root_admin';
        }

        return Scaffold(
          backgroundColor: backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Text('CÀI ĐẶT HỆ THỐNG', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildAdminProfile(name, role),
                const SizedBox(height: 30),
                
                if (isRoot) ...[
                  _buildSectionTitle("Quản trị nhân sự"),
                  _buildSettingItem(
                    icon: Icons.person_add_alt_1,
                    title: "Tạo tài khoản Admin mới",
                    subtitle: "Cấp quyền truy cập hệ thống",
                    onTap: showAddAdminDialog,
                    color: Colors.blue,
                  ),
                  _buildSettingItem(
                    icon: Icons.person_remove_alt_1,
                    title: "Thu hồi tài khoản Admin",
                    subtitle: "Xóa quyền truy cập của nhân sự",
                    onTap: showRevokeAdminDialog,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 20),
                ],

                _buildSectionTitle("Bảo mật & Hệ thống"),
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: "Đổi mật khẩu cá nhân",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                ),
                _buildSettingItem(
                  icon: Icons.logout,
                  title: "Đăng xuất tài khoản",
                  color: Colors.red,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Provider.of<UserProvider>(context, listen: false).setUserId("");
                    }
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildAdminProfile(String name, String role) {
    String displayRole = role == 'root_admin' ? "root_admin" : "admin";
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(role == 'root_admin' ? Icons.stars : Icons.admin_panel_settings, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Cấp bậc: $displayRole", 
                style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title.toUpperCase(), 
        style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildSettingItem({required IconData icon, required String title, String? subtitle, required VoidCallback onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? primaryColor),
        title: Text(title, style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}