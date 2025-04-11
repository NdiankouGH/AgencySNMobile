import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String name;
  final String email;
  final String telephone;
  final DateTime createdAt;

  UserModel({
    required this.name,
    required this.email,
    required this.telephone,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] ?? DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'telephone': telephone,
      'createdAt': createdAt,
    };
  }
}
