import 'order_status.dart';
import 'order_detail.dart';

class Order {
  final int id;              
  final String orderCode;       
  final OrderType orderType; 
  final int? tableId;
  final String? tableName;    
  final OrderStatus status;     
  final PaymentStatus paymentStatus;
    final double totalAmount;
  final double discountAmount;
  final double taxAmount;
  final String? note;
  final DateTime createdDate;
  final String createdByUserId;
  final List<OrderDetail> items;
  final int kitchenPrintCount;
  final String discountType;
  final double finalAmount;

  Order({
    required this.id,
    required this.orderCode,
    required this.orderType,
    this.tableId,
    this.tableName,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.note,
    required this.createdDate,
    required this.createdByUserId,
    required this.items,
    this.kitchenPrintCount = 0,
    this.discountType = 'NONE',
    this.finalAmount = 0,
  });

  Order copyWith({
    int? id,
    int? tableId,
    String? tableName,
    String? orderCode,
    OrderType? orderType,
    PaymentStatus? paymentStatus,
    String? createdByUserId,
    DateTime? createdDate,
    OrderStatus? status,
    double? totalAmount,
    List<OrderDetail>? items,
    String? note,
    int? kitchenPrintCount,
    double? discountAmount,
    String? discountType,
    double? finalAmount,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      orderCode: orderCode ?? this.orderCode,
      orderType: orderType ?? this.orderType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      note: note ?? this.note,
      kitchenPrintCount: kitchenPrintCount ?? this.kitchenPrintCount,
      // [THÊM]
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      finalAmount: finalAmount ?? this.finalAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_code': orderCode,
      'order_type': orderType == OrderType.dineIn ? 'DINE_IN' : 'TAKE_AWAY',
      'table_id': tableId,
      'table_name': tableName,
      'status': status == OrderStatus.completed ? 'COMPLETED' : 'PENDING',
      'payment_status': paymentStatus == PaymentStatus.paid ? 'PAID' : 'UNPAID',
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'note': note,
      'created_by_user_id': createdByUserId,
      'items': items.map((item) => item.toJson()).toList(),
      'kitchen_print_count': kitchenPrintCount, 
      'discount_type': discountType,
      'final_amount': finalAmount,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      orderCode: json['order_code']?.toString() ?? '',
      orderType: (json['order_type'] == 'TAKE_AWAY') ? OrderType.takeAway : OrderType.dineIn,
      tableId: json['table_id'] != null ? int.tryParse(json['table_id'].toString()) : null,
      tableName: json['table_name']?.toString(),
      status: _parseStatus(json['status']?.toString()),
      paymentStatus: _parsePaymentStatus(json['payment_status']?.toString()),
      
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      note: json['note']?.toString(),
      createdDate: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      createdByUserId: json['created_by_user_id']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderDetail.fromJson(item))
          .toList() ?? [],
      kitchenPrintCount: int.tryParse(json['kitchen_print_count']?.toString() ?? '0') ?? 0,
      discountType: json['discount_type']?.toString() ?? 'NONE',
      finalAmount: double.tryParse(json['final_amount']?.toString() ?? '0') ?? 0.0,
    );
  }

  factory Order.fromJsonSummary(Map<String, dynamic> json) {
     return Order(
        id: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
        orderCode: json['order_code']?.toString() ?? '',
        orderType: OrderType.dineIn,
        tableId: json['table_id'] != null ? int.tryParse(json['table_id'].toString()) : null,
        tableName: json['table_name']?.toString(),
        status: _parseStatus(json['status']?.toString()),
        paymentStatus: _parsePaymentStatus(json['payment_status']?.toString()),
        totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
        createdDate: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        createdByUserId: '',
        items: [],
        kitchenPrintCount: int.tryParse(json['kitchen_print_count']?.toString() ?? '0') ?? 0, 
        discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
        finalAmount: double.tryParse(json['final_amount']?.toString() ?? '0') ?? 0.0,
     );
  }
  
  static OrderStatus _parseStatus(String? status) {
    if (status == 'COMPLETED') return OrderStatus.completed;
    if (status == 'CANCELLED') return OrderStatus.cancelled;
    return OrderStatus.pending;
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    if (status == 'PAID') return PaymentStatus.paid;
    if (status == 'REFUNDED') return PaymentStatus.refunded;
    return PaymentStatus.unpaid;
  }
}