class Modifier {
  final String id;
  final String name;
  final double extraPrice;
  final String groupId;

  Modifier({
    required this.id,
    required this.name,
    required this.extraPrice,
    required this.groupId,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id']?.toString() ?? '',
      
      name: json['name'] ?? '',
      
      extraPrice: (json['extraPrice'] is int)
          ? (json['extraPrice'] as int).toDouble()
          : (json['extraPrice'] as double? ?? 0.0),
          
      groupId: json['groupId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extraPrice': extraPrice,
      'groupId': groupId,
    };
  }
}