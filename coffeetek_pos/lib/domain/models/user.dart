class User {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final String pinCode;
  final bool isActive;
  final DateTime createAt;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.pinCode,
    this.isActive = true,
    required this.createAt,
  });

  bool get isManager => role == 'admin' || role == 'manager';

factory User.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateVal) {
      if (dateVal == null) return DateTime.now();
      if (dateVal is DateTime) return dateVal;
      return DateTime.tryParse(dateVal.toString()) ?? DateTime.now();
    }

    bool parseBool(dynamic val) {
      if (val == true || val == 1 || val == '1') return true;
      return false;
    }

    return User(
      id: json['user_id'].toString(),
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? 'Nhân viên mới',
      role: json['role'] ?? 'cashier',
      avatarUrl: json['avatar_url'],
      
      pinCode: json['pin_code'] ?? '000000', 
      isActive: json['is_active'] != null ? parseBool(json['is_active']) : true,
      createAt: parseDate(json['join_date'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'avatar_url': avatarUrl,
      
      'pin_code': pinCode,
      'is_active': isActive ? 1 : 0,
      'join_date': createAt.toIso8601String(),
    };
  }
}