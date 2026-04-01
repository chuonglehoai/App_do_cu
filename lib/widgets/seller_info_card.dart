import 'package:flutter/material.dart';
import '../services/user_service.dart'; // Import service vừa tạo

class SellerInfoCard extends StatelessWidget {
  final String sellerId;
  final Color primaryColor;

  const SellerInfoCard({
    super.key, 
    required this.sellerId, 
    this.primaryColor = const Color(0xFF3E8B98),
  });

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: userService.getUserInfo(sellerId),
      builder: (context, snapshot) {
        // Mặc định khi đang tải hoặc lỗi
        String name = "Đang tải...";
        String? avatarUrl;

        if (snapshot.hasData && snapshot.data != null) {
          name = snapshot.data!['fullName'] ?? "Người dùng";
          avatarUrl = snapshot.data!['avatar'];
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) 
                    ? NetworkImage(avatarUrl) : null,
                child: (avatarUrl == null || avatarUrl.isEmpty) 
                    ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Text("Đang hoạt động", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}