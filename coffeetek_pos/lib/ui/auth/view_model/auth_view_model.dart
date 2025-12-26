import 'package:flutter/material.dart';
import '../../../domain/models/user.dart';
import '../../../data/repositories/auth_repository_impl.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl();

  User? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> loginWithPin(String pin) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final user = await _authRepository.loginWithPin(pin);

      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Mã PIN không chính xác!';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}