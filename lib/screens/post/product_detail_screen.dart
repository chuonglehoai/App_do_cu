import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../widgets/seller_info_card.dart';
import '../../services/post/product_detail_service.dart'; // Import controller

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isAdminView;
  const ProductDetailScreen({super.key, required this.product,this.isAdminView = false,});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ProductDetailService {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageHeader(context, widget.product.images),
                _buildProductInfo(widget.product.title, widget.product.price.toString(), widget.product.category),
                _buildTransactionBento(widget.product.address),
                _buildDescription(widget.product.description),
                SellerInfoCard(
                  sellerId: widget.product.sellerId,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 140),
              ],
            ),
          ),
          _buildBottomActionBar(context, widget.isAdminView),
        ],
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context, List<String> images) {
    return Stack(
      children: [
        SizedBox(
          height: 400,
          width: double.infinity,
          child: images.isNotEmpty
              ? PageView.builder(
                  controller: pageController,
                  onPageChanged: (index) {
                    setState(() => currentPage = index);
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => openFullScreenImage(index),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                )
              : Image.network("https://via.placeholder.com/400x400", fit: BoxFit.cover),
        ),
        IgnorePointer(
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${currentPage + 1}/${images.length}",
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(String title, String price, String category) {
    final double numericPrice = double.tryParse(price) ?? 0;
    final bool isFree = numericPrice == 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.beVietnamPro(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            isFree ? "Tặng" : "${price} VNĐ",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isFree ? const Color(0xFF6BBF59) : primaryColor),
          ),
          const SizedBox(height: 16),
          _buildChip(Icons.book, category.toUpperCase()),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionBento(String location) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildBentoItem("Hình thức", Icons.handshake, "Trực tiếp"),
          const SizedBox(width: 12),
          _buildBentoItem("Địa điểm", Icons.location_on, location),
        ],
      ),
    );
  }

  Widget _buildBentoItem(String title, IconData icon, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 18, color: primaryColor),
                const SizedBox(width: 6),
                Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Mô tả chi tiết", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, bool isAdminView) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: isAdminView ? _buildAdminButtons() : _buildUserChatButton(),
      ),
    );
  }

  Widget _buildAdminButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => showRejectDialog(widget.product.toMap()), // Hàm từ controller
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Từ chối", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => handleApproveAction(widget.product.toMap()), // Hàm từ controller
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Duyệt tin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
  Widget _buildUserChatButton() {
    return ElevatedButton.icon(
      onPressed: handleChatAction,
      icon: const Icon(Icons.chat_bubble, color: Colors.white),
      label: const Text("Nhắn tin trao đổi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}