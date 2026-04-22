import 'dart:io';
import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/services/cloudinary_service.dart';
import 'package:app_do_cu/services/database_product.dart';
import 'package:app_do_cu/services/chat_navigation_helper.dart'; // Import thêm
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // Dùng XFile cho đa nền tảng
import 'package:provider/provider.dart';
import '../models/product_model.dart';

class AddPostScreen extends StatefulWidget {
  final Product? product;
  final bool isReadOnly;
  const AddPostScreen({super.key, this.product, this.isReadOnly = false});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);
  final Color backgroundLight = const Color(0xFFF6F7F7);
  final Color textColor = const Color(0xFF131616);
  final Color greyText = const Color(0xFF6C7C7F);
  final Color borderColor = const Color(0xFFDEE2E3);

  final CloudinaryService _imageService = CloudinaryService();
  final DatabaseProduct _productService = DatabaseProduct();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedCategory = 'Đồ gia dụng';
  List<XFile> _newImages = []; // Ảnh mới chọn từ máy
  List<String> _oldImageUrls = []; // Ảnh cũ từ Firebase
  bool _isUploading = false;
  bool _isDonation = false;

  final List<String> _categories = ['Đồ gia dụng', 'Đồ dùng học tập', 'Thiết bị điện tử'];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _titleController.text = widget.product!.title;
      _descController.text = widget.product!.description;
      _selectedCategory = widget.product!.category;
      _isDonation = widget.product!.price == 0;
      _priceController.text = widget.product!.price.toString();
      _oldImageUrls = List.from(widget.product!.images);
    }
  }

  Future<void> _pickImage() async {
    if ((_newImages.length + _oldImageUrls.length) >= 6) {
      _showMsg("Bạn chỉ được chọn tối đa 6 ảnh");
      return;
    }
    
    // Dòng 62: Đảm bảo picked có kiểu XFile?
    XFile? picked = await _imageService.pickImage(); 
    
    if (picked != null) {
      setState(() => _newImages.add(picked));
    }
  }

  Future<void> _submitPost({String? newStatus}) async {
    final userId = context.read<UserProvider>().userId;
    if (userId == null) return;

    if (_newImages.isEmpty && _oldImageUrls.isEmpty) {
      _showMsg("Vui lòng chọn ít nhất 1 ảnh");
      return;
    }

    setState(() => _isUploading = true);
    try {
      // 1. Upload ảnh mới lên Cloudinary
      List<String> uploadedUrls = [];
      for (var file in _newImages) {
        String? url = await _imageService.uploadImage(file, folderName: 'posts');
        if (url != null) uploadedUrls.add(url);
      }

      // 2. Gộp ảnh cũ còn lại và ảnh mới upload
      List<String> finalImages = [..._oldImageUrls, ...uploadedUrls];
      String userAddr = await _productService.getUserAddress(userId);

      bool success;
      if (widget.product == null) {
        // Tạo bài mới
        success = await _productService.addPost(
          sellerId: userId,
          title: _titleController.text.trim(),
          category: _selectedCategory,
          type: _isDonation ? 'Tặng' : 'Bán',
          price: _isDonation ? '0' : _priceController.text.trim(),
          description: _descController.text.trim(),
          imageUrls: finalImages,
          address: userAddr,
        );
      } else {
        // Cập nhật bài cũ
        success = await _productService.updatePost(
          productId: widget.product!.id,
          oldStatus: widget.product!.status,
          data: {
            'title': _titleController.text.trim(),
            'category': _selectedCategory,
            'price': double.tryParse(_priceController.text) ?? 0,
            'description': _descController.text.trim(),
            'images': finalImages,
            'status': newStatus ?? widget.product!.status,
            'rejectReason': null, // Xóa lý do từ chối nếu có khi đăng lại
          },
        );
      }

      if (success && mounted) {
        Navigator.pop(context);
        _showMsg("Thao tác thành công!");
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePost() async {
    bool confirm = await _showConfirmDialog("Bạn có chắc chắn muốn xóa bài đăng này?");
    if (confirm && widget.product != null) {
      setState(() => _isUploading = true);
      await _productService.deletePost(widget.product!.id, widget.product!.status, widget.product!.category);
      if (mounted) {
        setState(() => _isUploading = false);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<UserProvider>().userId;
    final bool isOwner = widget.product == null || userId == widget.product?.sellerId;
    final String currentStatus = widget.product?.status ?? 'pending';

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(widget.product == null ? 'Đăng tin mới' : 'Chi tiết bài đăng',
            style: GoogleFonts.beVietnamPro(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildImageSection(),
                  const SizedBox(height: 16),
                  _buildSectionContainer(
                    title: 'Thông tin sản phẩm',
                    children: [
                      _buildTextField(label: 'Tên sản phẩm', controller: _titleController, enabled: isOwner),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(enabled: isOwner),
                    ],
                  ),
                  _buildSectionContainer(
                    title: 'Giao dịch',
                    children: [
                      if (isOwner) _buildSegmentedControl(),
                      const SizedBox(height: 16),
                      if (!_isDonation)
                        _buildTextField(
                          label: 'Giá (VNĐ)',
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          enabled: isOwner,
                        ),
                    ],
                  ),
                  _buildSectionContainer(
                    title: 'Mô tả chi tiết',
                    children: [_buildTextField(label: 'Nội dung', maxLines: 4, controller: _descController, enabled: isOwner)],
                  ),
                  if (widget.product?.rejectReason != null)
                    _buildSectionContainer(
                      title: 'Lý do từ chối',
                      children: [Text(widget.product!.rejectReason!, style: const TextStyle(color: Colors.red))],
                    ),
                  const SizedBox(height: 24),
                  _buildActionButtons(isOwner, currentStatus),
                ],
              ),
            ),
    );
  }

  // --- WIDGETS ---

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: (_oldImageUrls.length + _newImages.length < 6) ? _oldImageUrls.length + _newImages.length + 1 : 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemBuilder: (context, index) {
          // Nút thêm ảnh
          if (index == _oldImageUrls.length + _newImages.length) {
            return GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.add_a_photo, color: primaryColor),
              ),
            );
          }
          // Hiển thị ảnh cũ (URL)
          if (index < _oldImageUrls.length) {
            return _buildImagePreview(url: _oldImageUrls[index], onRemove: () => setState(() => _oldImageUrls.removeAt(index)));
          }
          // Hiển thị ảnh mới (File)
          int newIndex = index - _oldImageUrls.length;
          return _buildImagePreview(file: _newImages[newIndex], onRemove: () => setState(() => _newImages.removeAt(newIndex)));
        },
      ),
    );
  }

  Widget _buildImagePreview({String? url, XFile? file, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: url != null
              ? Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
              : (kIsWeb ? Image.network(file!.path) : Image.file(File(file!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
        ),
        Positioned(
          top: 0, right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isOwner, String status) {
    // TRƯỜNG HỢP 1: Người xem không phải chủ bài viết (Người đi mua)
    if (!isOwner && widget.product != null) {
      return _buildLargeButton('Nhắn tin trao đổi', Icons.chat, () {
        ChatNavigationHelper.handleChatNavigation(
          context: context,
          currentUserId: context.read<UserProvider>().userId,
          product: widget.product!,
          mounted: mounted,
        );
      });
    }

    // TRƯỜNG HỢP 2: Chế độ TẠO MỚI (widget.product == null)
    if (widget.product == null) {
      return _buildLargeButton('Đăng bài', Icons.cloud_upload, () => _submitPost());
    }

    // TRƯỜNG HỢP 3: Chế độ CHỈNH SỬA của chủ bài viết (widget.product != null)
    return Column(
      children: [
        // Nút Thay đổi thông tin (hiện khi đang chờ duyệt) hoặc Đăng lại (khi bị từ chối)
        if (status == 'pending')
          _buildLargeButton('Thay đổi thông tin', Icons.edit, () => _submitPost()),
        if (status == 'refused')
          _buildLargeButton('Đăng lại bài', Icons.refresh, () => _submitPost(newStatus: 'pending')),
        
        // Luôn hiện nút Xóa nếu là chủ bài viết trong màn hình quản lý
        const SizedBox(height: 12),
        _buildLargeButton('Xóa bài đăng', Icons.delete, _deletePost, isDanger: true),
      ],
    );
  }

  Widget _buildLargeButton(String label, IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDanger ? Colors.red : primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // --- CÁC WIDGET PHỤ TRỢ KHÁC (Giữ nguyên style cũ của bạn) ---
  Widget _buildTextField({required String label, required TextEditingController controller, int maxLines = 1, TextInputType keyboardType = TextInputType.text, bool enabled = true}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      ),
    ]);
  }

  Widget _buildCategoryDropdown({bool enabled = true}) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      onChanged: enabled ? (val) => setState(() => _selectedCategory = val!) : null,
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      decoration: InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
    );
  }

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildSegmentedControl() {
    return Row(children: [
      Expanded(child: RadioListTile(title: const Text("Bán"), value: false, groupValue: _isDonation, onChanged: (v) => setState(() => _isDonation = v!))),
      Expanded(child: RadioListTile(title: const Text("Tặng"), value: true, groupValue: _isDonation, onChanged: (v) {
        setState(() => _isDonation = v!);
        _priceController.text = "0";
      })),
    ]);
  }

  Future<bool> _showConfirmDialog(String msg) async {
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

  void _showMsg(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}