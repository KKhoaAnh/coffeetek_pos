class Modifier {
  final String id;
  final String name;
  final double extraPrice;
  final String groupId;
  final bool allowInput;
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
      
      allowInput: json['is_input_required'] == true || json['is_input_required'] == 1,
      
      userInput: json['user_input'],
    );
  }
  
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extraPrice': extraPrice,
      'userInput': userInput,
      'modifier_id': id,
      'modifier_name': name,
      'group_id': groupId,
      'is_input_required': allowInput,
    };
  }
}