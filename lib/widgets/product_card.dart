import 'package:flutter/material.dart';
import '../models/product_model.dart'; // Import Model đã tách

class ProductCard extends StatelessWidget {
  final Product product; // Sử dụng Model thay vì biến rời rạc
  final VoidCallback onTap; // Thêm sự kiện khi nhấn vào thẻ

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Xác định màu sắc dựa trên giá trị hoặc category
    final Color themeColor = product.price == 0 ? const Color(0xFF6BBF59) : const Color(0xFF3E8B98);

    return GestureDetector(
      onTap: onTap, // Xử lý chuyển trang tại đây
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phần hình ảnh
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      product.images.isNotEmpty ? product.images[0] : 'https://via.placeholder.com/300x200',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  // Tag trạng thái (BÁN/TẶNG)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.price == 0 ? "TẶNG" : "BÁN",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Phần thông tin văn bản
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.address,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.price == 0 ? "Miễn phí" : "${product.price.toInt()} VNĐ",
                    style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}