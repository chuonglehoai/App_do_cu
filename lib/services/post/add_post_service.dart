import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../models/product_model.dart';
import '../../UserProvider.dart';
import '../cloudinary_service.dart';
import '../database_product.dart';
import '../../screens/post/add_post_screen.dart';

abstract class AddPostService extends State<AddPostScreen> {
  // Các hằng số màu sắc và style
  final Color primaryColor = const Color(0xFF3E8B98);
  final Color backgroundLight = const Color(0xFFF6F7F7);
  final Color textColor = const Color(0xFF131616);
  final Color greyText = const Color(0xFF6C7C7F);
  final Color borderColor = const Color(0xFFDEE2E3);

  final CloudinaryService imageService = CloudinaryService();
  final DatabaseProduct productService = DatabaseProduct();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  String selectedCategory = 'Đồ gia dụng';
  List<XFile> newImages = [];
  List<String> oldImageUrls = [];
  bool isUploading = false;
  bool isDonation = false;

  final List<String> categories = ['Đồ gia dụng', 'Đồ dùng học tập', 'Thiết bị điện tử'];

  // Logic chọn ảnh
  Future<void> pickImage() async {
    if ((newImages.length + oldImageUrls.length) >= 6) {
      showMsg("Bạn chỉ được chọn tối đa 6 ảnh");
      return;
    }
    XFile? picked = await imageService.pickImage();
    if (picked != null) {
      setState(() => newImages.add(picked));
    }
  }

  // Logic nộp bài
  Future<void> submitPost(Product? currentProduct, {String? newStatus}) async {
    final userId = context.read<UserProvider>().userId;
    if (userId == null) return;

    if (newImages.isEmpty && oldImageUrls.isEmpty) {
      showMsg("Vui lòng chọn ít nhất 1 ảnh");
      return;
    }

    setState(() => isUploading = true);
    try {
      List<String> uploadedUrls = [];
      for (var file in newImages) {
        String? url = await imageService.uploadImage(file, folderName: 'posts');
        if (url != null) uploadedUrls.add(url);
      }

      List<String> finalImages = [...oldImageUrls, ...uploadedUrls];
      String userAddr = await productService.getUserAddress(userId);

      bool success;
      if (currentProduct == null) {
        success = await productService.addPost(
          sellerId: userId,
          title: titleController.text.trim(),
          category: selectedCategory,
          type: isDonation ? 'Tặng' : 'Bán',
          price: isDonation ? '0' : priceController.text.trim(),
          description: descController.text.trim(),
          imageUrls: finalImages,
          address: userAddr,
        );
      } else {
        success = await productService.updatePost(
          productId: currentProduct.id,
          oldStatus: currentProduct.status,
          data: {
            'title': titleController.text.trim(),
            'category': selectedCategory,
            'price': double.tryParse(priceController.text) ?? 0,
            'description': descController.text.trim(),
            'images': finalImages,
            'status': newStatus ?? currentProduct.status,
            'rejectReason': null,
          },
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        showMsg("Thao tác thành công!");
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  // Logic xóa bài
  Future<void> deletePost(Product? product) async {
    bool confirm = await showConfirmDialog("Bạn có chắc chắn muốn xóa bài đăng này?");
    if (confirm && product != null) {
      setState(() => isUploading = true);
      await productService.deletePost(product.id, product.status, product.category);
      if (mounted) {
        setState(() => isUploading = false);
        Navigator.pop(context);
      }
    }
  }

  void showMsg(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<bool> showConfirmDialog(String msg) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }
}