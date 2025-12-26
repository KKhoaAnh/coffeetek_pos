class User {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'].toString(), 
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? 'Nhân viên',
      role: json['role'] ?? 'CASHIER',
      avatarUrl: json['avatar_url'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'avatar_url': avatarUrl,
    };
  }
}