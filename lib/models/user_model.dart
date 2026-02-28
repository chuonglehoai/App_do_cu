class UserModel {
  final String uid;
  final String fullName;
  final String email;

  UserModel({required this.uid, required this.fullName, required this.email});

  // Chuyển từ Map (Firebase) sang Model (Dart)
  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
    );
  }
}