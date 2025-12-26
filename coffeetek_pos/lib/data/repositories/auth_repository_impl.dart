import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/models/user.dart';
import '../../utils/constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final http.Client _client = http.Client();

  @override
  Future<User?> loginWithPin(String pin) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pin': pin}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['token']);
        
        if (data['user'] != null) {
             await prefs.setString('userId', data['user']['user_id'].toString());
             await prefs.setString('userRole', data['user']['role']);
        }

        return User.fromJson(data['user']);
      } else {
        print('Login failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Lỗi kết nối máy chủ');
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    await prefs.remove('userRole');
  }
}