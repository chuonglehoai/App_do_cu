import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart'; // Đảm bảo đã thêm image_picker vào pubspec.yaml

class CloudinaryService {
  // Cấu hình Cloudinary của bạn
  final cloudinary = CloudinaryPublic(
    'dmrc4myd6', 
    'App_do_cu', 
    cache: false,
  );

  // Khởi tạo ImagePicker để chọn ảnh từ thư viện
  final ImagePicker _picker = ImagePicker();

  // 1. HÀM CHỌN ẢNH TỪ THƯ VIỆN (Thay thế StorageService cũ)
  Future<File?> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Nén ảnh xuống 70% để tiết kiệm băng thông Cloudinary
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print("Lỗi khi chọn ảnh: $e");
      return null;
    }
  }

  // 2. HÀM TẢI ẢNH LÊN CLOUDINARY
  Future<String?> uploadImage(File imageFile, {String folderName = 'avatars'}) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path, 
          folder: folderName, // Sử dụng tham số truyền vào thay vì fix cứng
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print("Lỗi Cloudinary: $e");
      return null;
    }
  }
}