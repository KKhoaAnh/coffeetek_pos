// import 'product.dart';
import 'modifier/modifier.dart';

class OrderDetail {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double totalLineAmount;
  final String note;
  final List<Modifier> modifiers;
  int committedQuantity; 

  OrderDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.totalLineAmount,
    this.note = '',
    this.modifiers = const [],
    this.committedQuantity = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'total_line_amount': totalLineAmount,
      'note': note,
      'modifiers': modifiers.map((m) => {
        'id': m.id,
        'name': m.name,
        'extraPrice': m.extraPrice
      }).toList(),
    };
  }

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    List<Modifier> modifiersList = [];
    if (json['modifiers'] != null && json['modifiers'] is List) {
      modifiersList = (json['modifiers'] as List).map((m) {
        if (m == null) return Modifier(id: '', name: '', extraPrice: 0, groupId: '');
        
        return Modifier(
          id: m['id']?.toString() ?? '',
          name: m['name'] ?? '',
          extraPrice: double.tryParse(m['extraPrice']?.toString() ?? '0') ?? 0.0,
          groupId: '',
        );
      }).toList();
    }

    int parsedQuantity = int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;

    int parsedCommitted = json['committed_quantity'] != null
        ? (int.tryParse(json['committed_quantity'].toString()) ?? parsedQuantity)
        : parsedQuantity;

    return OrderDetail(
      id: json['order_detail_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] ?? 'Món không tên',
      
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      
      quantity: parsedQuantity,
      
      totalLineAmount: double.tryParse(json['total_line_amount']?.toString() ?? '0') ?? 0.0,
      
      note: json['note']?.toString() ?? '',
      
      modifiers: modifiersList,
      
      committedQuantity: parsedCommitted,
    );
  }

  OrderDetail copyWith({
    String? id,
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    double? totalLineAmount,
    String? note,
    List<Modifier>? modifiers,
    int? committedQuantity,
  }) {
    return OrderDetail(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      totalLineAmount: totalLineAmount ?? this.totalLineAmount,
      note: note ?? this.note,
      modifiers: modifiers ?? this.modifiers,
      committedQuantity: committedQuantity ?? this.committedQuantity,
    );
  }
}