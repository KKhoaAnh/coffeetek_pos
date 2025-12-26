import '../models/user.dart';

abstract class AuthRepository {
  Future<User?> loginWithPin(String pin);
  Future<void> logout();
}