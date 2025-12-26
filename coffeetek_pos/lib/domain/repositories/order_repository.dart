import '../models/order.dart';

abstract class OrderRepository {
  Future<String?> createOrder(Order order);
  Future<List<Order>> getPendingOrders();
  Future<Order?> getOrderById(String orderId);
  // Future<bool> moveTable(int currentTableId, int targetTableId);
  // Future<bool> mergeTable(int sourceTableId, int targetTableId);
  Future<int> incrementKitchenPrintCount(String orderId);
}
