import 'dart:io';
import 'package:app_do_cu/UserProvider.dart';
import 'package:app_do_cu/services/cloudinary_service.dart';
import 'package:app_do_cu/services/database_product.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

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
  List<File> _selectedImages = [];
  bool _isUploading = false;
  bool _isDonation = false;

  final List<String> _categories = ['Đồ gia dụng', 'Đồ dùng học tập', 'Thiết bị điện tử', 'Khác'];

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 6) {
      _showMsg("Bạn chỉ được chọn tối đa 6 ảnh");
      return;
    }
    File? picked = await _imageService.pickImage();
    if (picked != null) {
      setState(() => _selectedImages.add(picked));
    }
  }

  void _showFullScreenImage(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(imageFile, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    final userId = context.read<UserProvider>().userId;
    if (_selectedImages.isEmpty || _titleController.text.trim().isEmpty) {
      _showMsg("Vui lòng nhập tên sản phẩm và chọn ít nhất 1 ảnh");
      return;
    }

    setState(() => _isUploading = true);
    try {
      List<String> imageUrls = [];
      for (var file in _selectedImages) {
        String? url = await _imageService.uploadImage(file, folderName: 'posts');
        if (url != null) imageUrls.add(url);
      }

      String userAddr = await _productService.getUserAddress(userId!);

      bool success = await _productService.addPost(
        sellerId: userId,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        type: _isDonation ? 'Tặng' : 'Bán',
        price: _isDonation ? '0' : _priceController.text.trim(),
        description: _descController.text.trim(),
        imageUrls: imageUrls,
        address: userAddr,
      );

      if (success && mounted) {
        Navigator.pop(context);
        _showMsg("Đăng tin thành công!");
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showMsg(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context), // Lệnh để quay lại trang trước
        ),
        title: Text('Đăng tin mới', style: GoogleFonts.beVietnamPro(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isUploading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // SỬA LỖI: Hiển thị Grid ảnh nếu đã có ảnh, nếu chưa thì hiện vùng chọn ảnh to
                _selectedImages.isEmpty ? _buildUploadArea() : _buildImageGrid(),
                const SizedBox(height: 16),
                _buildSectionContainer(
                  title: 'Thông tin chung',
                  children: [
                    _buildTextField(label: 'Tên sản phẩm', hint: 'VD: Giải tích 1', controller: _titleController),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionContainer(
                  title: 'Hình thức giao dịch',
                  children: [
                    _buildSegmentedControl(),
                    if (!_isDonation) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Giá sản phẩm',
                        hint: '0',
                        suffixText: 'VNĐ',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionContainer(
                  title: 'Mô tả',
                  children: [_buildTextField(label: 'Chi tiết', hint: 'Tình trạng...', maxLines: 4, controller: _descController)],
                ),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
    );
  }

  // --- CÁC WIDGET HỖ TRỢ ---

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2), 
        ),
        child: Column(
          children: [
            Icon(Icons.add_a_photo_outlined, color: primaryColor, size: 40),
            const SizedBox(height: 16),
            Text('Thêm hình ảnh sản phẩm', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tải lên tối đa 6 ảnh', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _selectedImages.length < 6 ? _selectedImages.length + 1 : 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10
        ),
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.add_photo_alternate_outlined, color: primaryColor),
              ),
            );
          }
          return _buildImagePreview(index);
        },
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showFullScreenImage(_selectedImages[index]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_selectedImages[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          ),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _selectedImages.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, String? suffixText, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w500, color: textColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixText != null ? Padding(padding: const EdgeInsets.all(12), child: Text(suffixText, style: const TextStyle(fontWeight: FontWeight.bold))) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor), borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
      decoration: InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
    );
  }

  Widget _buildSectionContainer({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }

  Widget _buildSegmentedControl() {
    return Row(
      children: [
        _buildSegmentItem('Bán', isSelected: !_isDonation, onPress: () => setState(() => _isDonation = false)),
        _buildSegmentItem('Tặng', isSelected: _isDonation, onPress: () {
          setState(() => _isDonation = true);
          _priceController.text = '0';
        }),
      ],
    );
  }

  Widget _buildSegmentItem(String label, {bool isSelected = false, VoidCallback? onPress}) {
    return Expanded(
      child: GestureDetector(
        onTap: onPress,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(6), boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? primaryColor : greyText)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submitPost,
        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Đăng tin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}