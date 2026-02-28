import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  void setUserId(String id) {
    _userId = id;
    notifyListeners(); // Thông báo cho tất cả các màn hình đang dùng userId cập nhật lại UI
  }

  void logout() {
    _userId = null;
    notifyListeners();
  }
}