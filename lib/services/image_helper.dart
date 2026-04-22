import 'package:image_picker/image_picker.dart'; // Sử dụng XFile thay vì File
import 'cloudinary_service.dart';

class ImageHelper {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // --- HÀM 1: CHỌN VÀ TẢI 1 ẢNH (Dùng cho Chat/Avatar) ---
  Future<String?> pickAndUploadSingle({String folder = 'chats'}) async {
    // 1. Chọn ảnh (Hàm này trong CloudinaryService phải trả về XFile?)
    final XFile? imageFile = await _cloudinaryService.pickImage();
    
    if (imageFile == null) return null;

    // 2. Tải lên và trả về URL (Hàm này trong CloudinaryService phải nhận XFile)
    return await _cloudinaryService.uploadImage(imageFile, folderName: folder);
  }

  // --- HÀM 2: CHỌN VÀ TẢI NHIỀU ẢNH (Dùng cho Đăng bài) ---
  Future<List<String>> pickAndUploadMultiple({String folder = 'posts', int limit = 6}) async {
    List<String> uploadedUrls = [];
    final ImagePicker picker = ImagePicker();
    
    try {
      // Sử dụng pickMultiImage để chọn nhiều ảnh cùng lúc thay vì chọn từng cái
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 70, // Nén ảnh để tải lên nhanh hơn
      );

      if (images.isEmpty) return [];

      // Giới hạn số lượng ảnh nếu cần
      final selectedImages = images.take(limit).toList();

      for (var image in selectedImages) {
        String? url = await _cloudinaryService.uploadImage(image, folderName: folder);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }
    } catch (e) {
      print("Lỗi khi chọn nhiều ảnh: $e");
    }
    
    return uploadedUrls;
  }
}