import 'package:app_do_cu/screens/product_detail_screen.dart';
import 'package:app_do_cu/widgets/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../UserProvider.dart';
import 'package:app_do_cu/models/product_model.dart'; // Đảm bảo bạn đã tạo file này
import '../widgets/search_bar_widget.dart';
import '../widgets/category_item.dart';
import '../widgets/product_card.dart';
import 'ProfileScreen.dart';
import 'ManagePostsScreen.dart';
import 'chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Đồ dùng học tập';
  String _searchQuery = "";

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Đồ dùng học tập', 'icon': Icons.menu_book},
    {'label': 'Đồ gia dụng', 'icon': Icons.home},
    {'label': 'Thiết bị điện tử', 'icon': Icons.bolt},
  ];

  String _getAvatarLetter(String fullName) {
    if (fullName.trim().isEmpty) return "U";
    List<String> nameParts = fullName.trim().split(RegExp(r'\s+'));
    return nameParts.last[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F7),
      appBar: _buildHeader(userProvider),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              hintText: 'Tìm trong mục $_selectedCategory...',
              onSearch: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
          _buildCategorySection(),
          _buildProductSection(),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  PreferredSizeWidget _buildHeader(UserProvider userProvider) {
    String name = userProvider.fullName ?? "Người dùng";
    bool hasAvatar = userProvider.avatarUrl != null && userProvider.avatarUrl!.isNotEmpty;

    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF3E8B98),
            backgroundImage: hasAvatar ? NetworkImage(userProvider.avatarUrl!) : null,
            child: !hasAvatar 
                ? Text(_getAvatarLetter(name), style: const TextStyle(color: Colors.white)) 
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: GoogleFonts.beVietnamPro(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('DANH MỤC PHỔ BIẾN',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _categories.map((cat) {
              bool isSelected = _selectedCategory == cat['label'];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat['label'];
                    });
                  },
                  child: CategoryItem(
                    icon: cat['icon'],
                    label: cat['label'],
                    isPrimary: isSelected,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductSection() {
    final Query categoryQuery = FirebaseDatabase.instance.ref("posted").child(_selectedCategory);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mục $_selectedCategory',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: categoryQuery.onValue,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<Product> products = [];
              if (snapshot.data!.snapshot.exists) {
                Map<dynamic, dynamic> postsData = snapshot.data!.snapshot.value as Map;

                postsData.forEach((postId, postData) {
                  var product = Product.fromMap(Map<String, dynamic>.from(postData), postId);
                  if (_searchQuery.isEmpty || product.title.toLowerCase().contains(_searchQuery)) {
                    products.add(product);
                  }
                });
                // Sắp xếp mới nhất lên đầu
                products.sort((a, b) => b.id.compareTo(a.id)); 
              }

              if (products.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("Không tìm thấy kết quả phù hợp"),
                ));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  // home_screen.dart dòng 182-192
                  return ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: product, // Truyền trực tiếp object product
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  
}