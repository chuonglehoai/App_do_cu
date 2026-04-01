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
  });

  // Chuyển đổi dữ liệu từ Firebase thành đối tượng Product
  factory Product.fromMap(Map<dynamic, dynamic> map, String id) {
    // Xử lý danh sách hình ảnh an toàn từ Firebase
    List<String> imageList = [];
    if (map['images'] != null) {
      if (map['images'] is List) {
        imageList = List<String>.from(map['images']);
      } else if (map['images'] is Map) {
        // Trường hợp Firebase lưu dưới dạng Map với key tự động
        Map<dynamic, dynamic> imagesMap = map['images'];
        imageList = imagesMap.values.map((e) => e.toString()).toList();
      }
    }
    return Product(
      id: id,
      title: map['title'] ?? '',
      price: double.tryParse(map['price']?.toString() ?? '0') ?? 0,
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      sellerId: map['sellerId'] ?? 'Người dùng',
      images: List<String>.from(map['images'] ?? []),
      category: map['category'] ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }
}