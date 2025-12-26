import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../utils/constants.dart';

class OrderRepositoryImpl implements OrderRepository {
  
  final http.Client _client = http.Client();
  @override
  Future<String?> createOrder(Order order) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(order.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['order_id'].toString(); 
      }
      return null;
    } catch (e) {
      print('Create order error: $e');
      return null;
    }
  }

  @override
  Future<List<Order>> getPendingOrders() async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/orders/pending');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Order.fromJsonSummary(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getPendingOrders: $e');
      return [];
    }
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/orders/$orderId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return Order.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error getOrderById: $e');
      return null;
    }
  }

  Future<bool> updateOrder(Order order) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/orders/${order.id}');
      print('PUT Update Order: $uri');
      
      final body = json.encode(order.toJson());
      
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        print('Cập nhật đơn thành công');
        return true;
      } else {
        print('Lỗi cập nhật: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception updateOrder: $e');
      return false;
    }
  }

  @override
  Future<int> incrementKitchenPrintCount(String orderId) async {
    try {
      final response = await http.put(Uri.parse('${AppConstants.baseUrl}/orders/$orderId/print-count'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['print_count'] as int?) ?? 1;
      }
    } catch (e) {
      print("Lỗi tăng print count: $e");
    }
    return 0;
  }
}