import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' show UserCredential, FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);
  final Color backgroundLight = const Color(0xFFF6F7F7);
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  void _showAddAdminDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Tạo tài khoản Admin", 
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField("Tên đăng nhập", nameController, Icons.person_outline),
            const SizedBox(height: 12),
            _buildDialogField("Email", emailController, Icons.email_outlined),
            const SizedBox(height: 12),
            _buildDialogField("Mật khẩu", passwordController, Icons.lock_outline, isPassword: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              String email = emailController.text.trim();
              String name = nameController.text.trim();
              String password = passwordController.text.trim();

              if (email.isEmpty || name.isEmpty || password.isEmpty) return;

              try {
                // 1. TẠO TÀI KHOẢN TRONG FIREBASE AUTH
                // Lưu ý: Việc này sẽ tự động đăng nhập vào tài khoản mới tạo
                UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                String? newAdminUid = result.user?.uid;

                if (newAdminUid != null) {
                  // 2. LƯU THÔNG TIN VÀO DATABASE VỚI KEY LÀ UID VỪA TẠO
                  await FirebaseDatabase.instance.ref("admins/$newAdminUid").set({
                    "adminId": newAdminUid,
                    "fullName": name,
                    "email": email,
                    "role": "admin",
                    "createdAt": ServerValue.timestamp,
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    _showSnackBar("Đã tạo Admin thành công trên cả hệ thống xác thực!");
                  }
                }
              } catch (e) {
                _showSnackBar("Lỗi: ${e.toString()}");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E8B98)),
            child: const Text("Tạo ngay", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- HÀM THU HỒI TÀI KHOẢN ---
  void _showRevokeAdminDialog() {
    final currentAdminId = context.read<UserProvider>().userId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thu hồi quyền Admin"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder(
            stream: _dbRef.child("admins").onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Text("Không có admin nào");
              
              Map data = snapshot.data!.snapshot.value as Map;
              List admins = data.values.where((a) => a['adminId'] != currentAdminId).toList();

              return ListView.builder(
                shrinkWrap: true,
                itemCount: admins.length,
                itemBuilder: (context, index) {
                  final admin = admins[index];
                  return ListTile(
                    title: Text(admin['fullName']),
                    subtitle: Text(admin['email']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () async {
                        await _dbRef.child("admins/${admin['adminId']}").remove();
                        if (mounted) Navigator.pop(context);
                        _showSnackBar("Đã thu hồi tài khoản ${admin['fullName']}");
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String adminId = context.read<UserProvider>().userId ?? "";

    return FutureBuilder<DataSnapshot>(
      future: _dbRef.child("admins").child(adminId).get(),
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
                
                // --- CHỈ HIỂN THỊ NẾU LÀ ROOT_ADMIN ---
                if (isRoot) ...[
                  _buildSectionTitle("Quản trị nhân sự"),
                  _buildSettingItem(
                    icon: Icons.person_add_alt_1,
                    title: "Tạo tài khoản Admin mới",
                    subtitle: "Cấp quyền truy cập hệ thống",
                    onTap: _showAddAdminDialog,
                    color: Colors.blue,
                  ),
                  _buildSettingItem(
                    icon: Icons.person_remove_alt_1,
                    title: "Thu hồi tài khoản Admin",
                    subtitle: "Xóa quyền truy cập của nhân sự",
                    onTap: _showRevokeAdminDialog,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 20),
                ],

                _buildSectionTitle("Bảo mật & Hệ thống"),
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: "Đổi mật khẩu cá nhân",
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.logout,
                  title: "Đăng xuất tài khoản",
                  color: Colors.red,
                  onTap: () async {
                    // 1. Đăng xuất khỏi Firebase Auth
                    await FirebaseAuth.instance.signOut();

                    // 2. Xóa UID trong Provider (nếu bạn có dùng UserProvider để lưu userId)
                    if (context.mounted) {
                      Provider.of<UserProvider>(context, listen: false).setUserId("");
                    }

                    // 3. Điều hướng và XÓA SẠCH các màn hình trước đó (để không nhấn Back quay lại được)
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false, // Xóa tất cả các route cũ trong ngăn xếp
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

  Widget _buildDialogField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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