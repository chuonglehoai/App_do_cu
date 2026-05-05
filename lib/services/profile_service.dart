import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:provider/provider.dart';
import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/services/database_profile.dart';
import 'package:app_do_cu/showError.dart';
import '../screens/profile_screen.dart';

abstract class ProfileService extends State<ProfileScreen> {
  final DatabaseService dbService = DatabaseService();
  
  Map<dynamic, dynamic> userData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final userId = context.read<UserProvider>().userId;
    
    if (userId == null || userId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final data = await dbService.getUserData(userId);
    if (mounted) {
      setState(() {
        userData = data ?? {};
        isLoading = false;
      });
    }
  }
  
  Future<void> handleUpdateAvatar() async {
    setState(() => isLoading = true);
    final userId = context.read<UserProvider>().userId;
    String? newUrl = await dbService.uploadAndSaveAvatar(userId!); 
    
    if (newUrl != null) {
      await loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green),
      );
    }
    
    setState(() => isLoading = false);
  }

  Future<void> handleLogout() async {
    Provider.of<UserProvider>(context, listen: false).setUserId("");
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void showUpdateDialog() {
    final nameController = TextEditingController(text: userData['fullName']);
    final phoneController = TextEditingController(text: userData['phone'] ?? '');
    final addressController = TextEditingController(text: userData['address'] ?? '');
    final studentIdController = TextEditingController(text: userData['studentId'] ?? '');
    const Color primaryColor = Color(0xFF3E8B98);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Để keyboard không che mất form
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Cập nhật hồ sơ', style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              _buildModernField(controller: nameController, label: 'Họ và tên', icon: Icons.person),
              const SizedBox(height: 15),
              _buildModernField(controller: studentIdController, label: 'Mã số sinh viên', icon: Icons.badge),
              const SizedBox(height: 15),
              _buildModernField(controller: phoneController, label: 'Số điện thoại', icon: Icons.phone, keyType: TextInputType.phone),
              const SizedBox(height: 15),
              _buildModernField(controller: addressController, label: 'Địa chỉ/Trường học', icon: Icons.location_on),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final userId = Provider.of<UserProvider>(context, listen: false).userId;
                    if (userId != null) {
                      bool success = await DatabaseService().updateStudentInfo(
                        uid: userId,
                        fullName: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        studentId: studentIdController.text.trim(),
                        school: addressController.text.trim(),
                      );

                      if (success) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        loadData(); 
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã cập nhật thông tin!"), backgroundColor: Colors.green),
                        );
                      } else {
                        context.showError("Có lỗi xảy ra, vui lòng thử lại!");
                      }
                    }
                  },
                  child: Text('Lưu thay đổi', style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm phụ trợ để tạo TextField kiểu hiện đại
  Widget _buildModernField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon,
    TextInputType keyType = TextInputType.text
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyType,
      style: GoogleFonts.beVietnamPro(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3E8B98), size: 20),
        filled: true,
        fillColor: const Color(0xFFF6F7F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        floatingLabelStyle: const TextStyle(color: Color(0xFF3E8B98)),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}