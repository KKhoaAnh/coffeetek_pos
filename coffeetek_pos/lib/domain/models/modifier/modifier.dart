class Modifier {
  final String id;
  final String name;
  final double extraPrice;
  final String groupId;
  
  // [QUAN TRỌNG] Cờ cho phép nhập liệu
  final bool allowInput; 
  
  // Dữ liệu nhập từ bàn phím (Note)
  final String? userInput; 

  Modifier({
    required this.id,
    required this.name,
    required this.extraPrice,
    this.groupId = '',
    this.allowInput = false,
    this.userInput,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: (json['modifier_id'] ?? json['id']).toString(),
      name: json['modifier_name'] ?? json['name'] ?? '',
      extraPrice: double.tryParse((json['extra_price'] ?? json['price']).toString()) ?? 0.0,
      groupId: (json['group_id'] ?? '').toString(),
      
      // [FIX] Phải ánh xạ đúng key từ Backend gửi về
      // Backend gửi 'is_input_required', Model hứng vào 'allowInput'
      allowInput: (json['is_input_required'] == 1 || json['is_input_required'] == true),
      
      userInput: json['user_input'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modifier_id': id,
      'modifier_name': name,
      'extra_price': extraPrice,
      'group_id': groupId,
      'is_input_required': allowInput, 
      'user_input': userInput,
      
      // Các trường legacy hỗ trợ Cart cũ
      'id': id,
      'name': name,
      'price': extraPrice,
    };
  }
  
  // Hàm copyWith để cập nhật trạng thái khi nhập liệu
  Modifier copyWith({
    String? id,
    String? name,
    double? extraPrice,
    String? groupId,
    bool? allowInput,
    String? userInput,
  }) {
    return Modifier(
      id: id ?? this.id,
      name: name ?? this.name,
      extraPrice: extraPrice ?? this.extraPrice,
      groupId: groupId ?? this.groupId,
      allowInput: allowInput ?? this.allowInput,
      userInput: userInput ?? this.userInput,
    );
  }
}