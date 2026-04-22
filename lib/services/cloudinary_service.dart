import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart'; 

class CloudinaryService {
  // Cấu hình Cloudinary
  final cloudinary = CloudinaryPublic(
    'dmrc4myd6', 
    'App_do_cu', 
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  // 1. HÀM CHỌN ẢNH (Trả về XFile để dùng được cho cả Web)
  Future<XFile?> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      return pickedFile; 
    } catch (e) {
      print("Lỗi khi chọn ảnh: $e");
      return null;
    }
  }

  // 2. HÀM TẢI ẢNH (Đã đổi tham số từ File thành XFile)
  Future<String?> uploadImage(XFile imageFile, {String folderName = 'avatars'}) async {
    try {
      // CloudinaryPublic hỗ trợ tải lên từ path của XFile
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path, 
          folder: folderName, 
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print("Lỗi Cloudinary: $e");
      return null;
    }
  }
}