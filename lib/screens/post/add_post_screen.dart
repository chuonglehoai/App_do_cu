import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../UserProvider.dart';
import '../../services/chat/chat_navigation_helper.dart';
import '../../services/post/add_post_service.dart'; 

class AddPostScreen extends StatefulWidget {
  final Product? product;
  final bool isReadOnly;
  const AddPostScreen({super.key, this.product, this.isReadOnly = false});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends AddPostService { // Kế thừa từ Controller
  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      titleController.text = widget.product!.title;
      descController.text = widget.product!.description;
      selectedCategory = widget.product!.category;
      isDonation = widget.product!.price == 0;
      priceController.text = widget.product!.price.toString();
      oldImageUrls = List.from(widget.product!.images);
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
      body: isUploading
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
                      _buildTextField(label: 'Tên sản phẩm', controller: titleController, enabled: isOwner),
                      const SizedBox(height: 16),
                      _buildCategoryDropdown(enabled: isOwner),
                    ],
                  ),
                  _buildSectionContainer(
                    title: 'Giao dịch',
                    children: [
                      if (isOwner) _buildSegmentedControl(),
                      const SizedBox(height: 16),
                      if (!isDonation)
                        _buildTextField(
                          label: 'Giá (VNĐ)',
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          enabled: isOwner,
                        ),
                    ],
                  ),
                  _buildSectionContainer(
                    title: 'Mô tả chi tiết',
                    children: [_buildTextField(label: 'Nội dung', maxLines: 4, controller: descController, enabled: isOwner)],
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

  // --- UI WIDGETS ---
  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: (oldImageUrls.length + newImages.length < 6) ? oldImageUrls.length + newImages.length + 1 : 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
        itemBuilder: (context, index) {
          if (index == oldImageUrls.length + newImages.length) {
            return GestureDetector(
              onTap: pickImage,
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.add_a_photo, color: primaryColor),
              ),
            );
          }
          if (index < oldImageUrls.length) {
            return _buildImagePreview(url: oldImageUrls[index], onRemove: () => setState(() => oldImageUrls.removeAt(index)));
          }
          int newIndex = index - oldImageUrls.length;
          return _buildImagePreview(file: newImages[newIndex], onRemove: () => setState(() => newImages.removeAt(newIndex)));
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

    if (widget.product == null) {
      return _buildLargeButton('Đăng bài', Icons.cloud_upload, () => submitPost(null));
    }

    return Column(
      children: [
        if (status == 'pending')
          _buildLargeButton('Thay đổi thông tin', Icons.edit, () => submitPost(widget.product)),
        if (status == 'refused')
          _buildLargeButton('Đăng lại bài', Icons.refresh, () => submitPost(widget.product, newStatus: 'pending')),
        const SizedBox(height: 12),
        _buildLargeButton('Xóa bài đăng', Icons.delete, () => deletePost(widget.product), isDanger: true),
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
      value: selectedCategory,
      onChanged: enabled ? (val) => setState(() => selectedCategory = val!) : null,
      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
      Expanded(child: RadioListTile(title: const Text("Bán"), value: false, groupValue: isDonation, onChanged: (v) => setState(() => isDonation = v!))),
      Expanded(child: RadioListTile(title: const Text("Tặng"), value: true, groupValue: isDonation, onChanged: (v) {
        setState(() => isDonation = v!);
        priceController.text = "0";
      })),
    ]);
  }
}