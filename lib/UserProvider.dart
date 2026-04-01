import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _fullName;
  String? _avatarUrl;

  String? get userId => _userId;
  String? get fullName => _fullName;
  String? get avatarUrl => _avatarUrl;

  void setUserId(String id) {
    _userId = id;
    notifyListeners(); // Thông báo cho tất cả các màn hình đang dùng userId cập nhật lại UI
  }
  void setFullName(String name) {
    _fullName = name;
    notifyListeners();
  }
  void setAvatarUrl(String url) {
    _avatarUrl = url;
    notifyListeners(); // Thông báo cho tất cả
  }
  void logout() {
    _userId = null;
    notifyListeners();
  }
}