import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/user.dart';
import '../../utils/constants.dart'; // Nơi chứa baseUrl

class UserService {
  final String _baseUrl = '${AppConstants.baseUrl}/users';

  // 1. Lấy danh sách
  Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi lấy danh sách user: $e");
      return [];
    }
  }

  // 2. Thêm mới
  Future<bool> createUser(User user) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': user.username,
          'full_name': user.fullName,
          'role': user.role,
          'pin_code': user.pinCode,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 3. Cập nhật
  Future<bool> updateUser(User user) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': user.fullName,
          'role': user.role,
          'pin_code': user.pinCode,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. Đổi trạng thái (Khóa/Mở)
  Future<bool> toggleStatus(String userId, bool isActive) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/$userId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_active': isActive}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}