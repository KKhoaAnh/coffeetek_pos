import 'product.dart';
import 'modifier/modifier.dart';

class CartItem {
  final String id; 
  final Product product;
  final List<Modifier> selectedModifiers;
  int quantity;
  final int committedQuantity;

  CartItem({
    required this.id,
    required this.product,
    this.selectedModifiers = const [],
    this.quantity = 1,
    this.committedQuantity = 0,
  });

  double get unitPrice {
    double modifierTotal = 0;
    for (var mod in selectedModifiers) {
      modifierTotal += mod.extraPrice;
    }
    return product.price + modifierTotal;
  }

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    List<Modifier>? selectedModifiers,
    int? quantity,
    int? committedQuantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      quantity: quantity ?? this.quantity,
      committedQuantity: committedQuantity ?? this.committedQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'selectedModifiers': selectedModifiers?.map((m) => m.toJson()).toList(),
      // ...
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      
      product: Product.fromJson(json['product']), 
      
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity'].toString()) ?? 1,
      
      selectedModifiers: json['selectedModifiers'] != null
          ? (json['selectedModifiers'] as List).map((m) => Modifier.fromJson(m)).toList()
          : [],
    );
  }
}