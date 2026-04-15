import 'dart:io';
import 'cloudinary_service.dart';

class ImageHelper {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // --- HÀM 1: CHỌN VÀ TẢI 1 ẢNH (Dùng cho Chat/Avatar) ---
  // Giúp bạn rút gọn logic: Chỉ gọi 1 hàm là có ngay URL ảnh
  Future<String?> pickAndUploadSingle({String folder = 'chats'}) async {
    // 1. Sử dụng hàm pickImage có sẵn trong CloudinaryService của bạn
    File? imageFile = await _cloudinaryService.pickImage();
    
    if (imageFile == null) return null;

    // 2. Tải lên và trả về URL
    return await _cloudinaryService.uploadImage(imageFile, folderName: folder);
  }

  // --- HÀM 2: CHỌN VÀ TẢI NHIỀU ẢNH (Dùng cho Đăng bài) ---
  // Tự động lặp và tải lên, trả về danh sách URL thành công
  Future<List<String>> pickAndUploadMultiple({String folder = 'posts'}) async {
    List<String> uploadedUrls = [];
    
    // Bạn có thể dùng hàm pickMultiImage của ImagePicker tại đây
    // hoặc lặp lại hàm pickImage đơn lẻ nhiều lần.
    // Ở đây tôi hướng dẫn cách lặp để tận dụng CloudinaryService của bạn:
    
    File? imageFile = await _cloudinaryService.pickImage();
    if (imageFile != null) {
      String? url = await _cloudinaryService.uploadImage(imageFile, folderName: folder);
      if (url != null) uploadedUrls.add(url);
    }
    
    return uploadedUrls;
  }
}