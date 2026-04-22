class Product {
  final String id;
  final String title;
  final double price;
  final String description;
  final String address;
  final String sellerId;
  final List<String> images;
  final String category;
  final String createdAt;
  // Bổ sung thêm các trường để quản lý trạng thái bài đăng
  final String status;       // pending (chờ), approved (đã đăng), refused (từ chối)
  final String? rejectReason; // Lý do từ chối nếu có

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.address,
    required this.sellerId,
    required this.images,
    required this.category,
    required this.createdAt,
    this.status = 'pending', // Mặc định là đang chờ duyệt
    this.rejectReason,
  });

  // Chuyển đổi dữ liệu từ Firebase thành đối tượng Product
  factory Product.fromMap(Map<dynamic, dynamic> map, String id) {
    // 1. Xử lý danh sách hình ảnh an toàn
    List<String> imageList = [];
    if (map['images'] != null) {
      if (map['images'] is List) {
        imageList = (map['images'] as List).map((e) => e.toString()).toList();
      } else if (map['images'] is Map) {
        Map<dynamic, dynamic> imagesMap = map['images'];
        imageList = imagesMap.values.map((e) => e.toString()).toList();
      }
    }

    // 2. Chuyển đổi price an toàn
    double parsedPrice = 0.0;
    if (map['price'] != null) {
      parsedPrice = double.tryParse(map['price'].toString()) ?? 0.0;
    }

    return Product(
      id: id,
      title: map['title'] ?? 'Không tiêu đề',
      price: parsedPrice,
      description: map['description'] ?? '',
      address: map['address'] ?? 'Chưa xác định',
      sellerId: map['sellerId'] ?? '',
      images: imageList,
      category: map['category'] ?? 'Khác',
      createdAt: map['createdAt']?.toString() ?? '',
      status: map['status'] ?? 'pending', // Lấy status từ Firebase
      rejectReason: map['rejectReason'],  // Lấy lý do từ chối (nếu có)
    );
  }

  // Chuyển đối tượng Product ngược lại thành Map để cập nhật/lưu Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'address': address,
      'sellerId': sellerId,
      'images': images,
      'category': category,
      'createdAt': createdAt,
      'status': status,
      if (rejectReason != null) 'rejectReason': rejectReason,
    };
  }
}