class ShiftModel {
  final int id;
  final int userId;
  final String userName; // [MỚI]
  final DateTime startTime;
  final DateTime? endTime;
  final double initialFloat;
  final String status;
  final String? note;    // [MỚI]
  final double totalCashSales; // [MỚI]
  final double expectedCash;   // [MỚI]
  final double actualCash;     // [MỚI]
  final double difference;

  ShiftModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.startTime,
    this.endTime,
    required this.initialFloat,
    required this.status,
    this.note,
    this.totalCashSales = 0,
    this.expectedCash = 0,
    this.actualCash = 0,
    this.difference = 0,
  });

  bool get isOpen => status == 'OPEN';

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['shift_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Nhân viên', // [MỚI]
      
      startTime: DateTime.parse(json['start_time'].toString()).toLocal(),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'].toString()).toLocal() : null,
      
      initialFloat: double.tryParse(json['initial_float'].toString()) ?? 0,
      status: json['status'],
      note: json['note'], // [MỚI]
      totalCashSales: double.tryParse(json['total_cash_sales']?.toString() ?? '0') ?? 0,
      expectedCash: double.tryParse(json['expected_cash']?.toString() ?? '0') ?? 0,
      actualCash: double.tryParse(json['actual_cash']?.toString() ?? '0') ?? 0,
      difference: double.tryParse(json['difference']?.toString() ?? '0') ?? 0,
    );
  }
}