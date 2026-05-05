import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show UserCredential, FirebaseAuth;
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../UserProvider.dart';
import '../../screens/admin/admin_settings_screen.dart';

abstract class AdminSettingsService extends State<AdminSettingsScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);
  final Color backgroundLight = const Color(0xFFF6F7F7);
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

  void showAddAdminDialog() {
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
            buildDialogField("Tên đăng nhập", nameController, Icons.person_outline),
            const SizedBox(height: 12),
            buildDialogField("Email", emailController, Icons.email_outlined),
            const SizedBox(height: 12),
            buildDialogField("Mật khẩu", passwordController, Icons.lock_outline, isPassword: true),
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
                UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );

                String? newAdminUid = result.user?.uid;

                if (newAdminUid != null) {
                  await FirebaseDatabase.instance.ref("admins/$newAdminUid").set({
                    "adminId": newAdminUid,
                    "fullName": name,
                    "email": email,
                    "role": "admin",
                    "createdAt": ServerValue.timestamp,
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    showSnackBar("Đã tạo Admin thành công trên cả hệ thống xác thực!");
                  }
                }
              } catch (e) {
                showSnackBar("Lỗi: ${e.toString()}");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E8B98)),
            child: const Text("Tạo ngay", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showRevokeAdminDialog() {
    final currentAdminId = context.read<UserProvider>().userId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thu hồi quyền Admin"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder(
            stream: dbRef.child("admins").onValue,
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
                        await dbRef.child("admins/${admin['adminId']}").remove();
                        if (mounted) Navigator.pop(context);
                        showSnackBar("Đã thu hồi tài khoản ${admin['fullName']}");
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

  Widget buildDialogField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
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

  void showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}