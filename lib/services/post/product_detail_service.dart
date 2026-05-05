import 'package:app_do_cu/services/admin/admin_service.dart' show AdminService;
import 'package:firebase_database/firebase_database.dart' show FirebaseDatabase;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../UserProvider.dart';
import '../chat/chat_service.dart';
import '../chat/chat_navigation_helper.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../../screens/post/product_detail_screen.dart';

abstract class ProductDetailService extends State<ProductDetailScreen> {
  final Color primaryColor = const Color(0xFF3E8B98);
  final Color backgroundLight = const Color(0xFFF6F7F7);
  final AdminService adminService = AdminService();
  bool isActualAdmin = false;
  
  late PageController pageController;
  int currentPage = 0;
  final ChatService chatService = ChatService();
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    _checkAdminPrivilege();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // Hàm mở xem ảnh toàn màn hình
  void openFullScreenImage(int initialIndex) {
    FullScreenImageViewer.open(
      context, 
      widget.product.images, 
      index: initialIndex
    );
  }

  Future<void> _checkAdminPrivilege() async {
    // Nếu tham số isAdminView truyền vào là false, không cần check Firebase
    if (!widget.isAdminView) return;

    final userId = context.read<UserProvider>().userId;
    if (userId == null) return;

    try {
      // Kiểm tra sự tồn tại của userId trong node admins
      final snapshot = await FirebaseDatabase.instance.ref("admins/$userId").get();
      
      if (mounted) {
        setState(() {
          // Nếu tồn tại dữ liệu trong node admins thì xác nhận là Admin
          isActualAdmin = snapshot.exists;
        });
      }
    } catch (e) {
      debugPrint("Lỗi kiểm tra quyền Admin: $e");
    }
  }

  // Hàm xử lý nhắn tin trao đổi
  Future<void> handleChatAction() async {
    final userProvider = context.read<UserProvider>();
    
    // 1. Chuẩn bị dữ liệu phòng chat
    List<String> ids = [userProvider.userId!, widget.product.sellerId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // 2. Gửi tin nhắn văn bản đầu tiên
    String productText = "Xin chào, mình muốn trao đổi về sản phẩm: ${widget.product.title}";
    await chatService.sendMessage(
      chatRoomId,
      userProvider.userId!,
      widget.product.sellerId,
      productText,
    );

    // 3. Gửi tin nhắn thứ hai chứa ảnh (nếu có)
    if (widget.product.images.isNotEmpty) {
      await chatService.sendMessage(
        chatRoomId,
        userProvider.userId!,
        widget.product.sellerId,
        widget.product.images[0],
      );
    }

    // 4. Chuyển sang màn hình chi tiết chat
    if (mounted) {
      ChatNavigationHelper.handleChatNavigation(
        context: context,
        currentUserId: userProvider.userId,
        product: widget.product,
        mounted: mounted,
      );
    }
  }
}