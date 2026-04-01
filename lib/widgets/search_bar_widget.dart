import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String)? onSearch; // Đổi tên để rõ nghĩa hơn

  const CustomSearchBar({
    super.key, 
    required this.hintText,
    this.onSearch, 
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng controller để lấy giá trị khi nhấn nút nếu cần
    final TextEditingController controller = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3E8B98).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search, // Hiển thị nút kính lúp trên bàn phím
        onSubmitted: onSearch, // Chỉ kích hoạt khi nhấn nút tìm kiếm trên bàn phím
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF3E8B98)),
          // Thêm nút icon để người dùng có thể nhấn trực tiếp
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF3E8B98)),
            onPressed: () => onSearch?.call(controller.text),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}