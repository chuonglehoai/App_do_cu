import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // 1. CHỌN ẢNH TỪ THƯ VIỆN
  Future<File?> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Nén ảnh để tải lên nhanh hơn
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // 2. TẢI ẢNH LÊN FIREBASE STORAGE
  Future<String?> uploadImage(File imageFile, String folderName) async {
    try {
      // Tạo tên file duy nhất dựa trên thời gian
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child(folderName).child(fileName);

      // Tải file lên
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Lấy URL sau khi tải xong để lưu vào Database
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Lỗi khi upload ảnh: $e");
      return null;
    }
  }

  // 3. XÓA ẢNH TRÊN FIREBASE STORAGE
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Lấy tham chiếu từ URL
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print("Lỗi khi xóa ảnh: $e");
      return false;
    }
  }

  // 4. THAY ĐỔI ẢNH (Xóa ảnh cũ và tải ảnh mới)
  Future<String?> updateImage(String oldImageUrl, File newImageFile, String folderName) async {
    try {
      // Xóa ảnh cũ trước
      if (oldImageUrl.isNotEmpty) {
        await deleteImage(oldImageUrl);
      }
      // Tải ảnh mới lên
      return await uploadImage(newImageFile, folderName);
    } catch (e) {
      print("Lỗi khi thay đổi ảnh: $e");
      return null;
    }
  }
}