import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../../../domain/models/product.dart';
import '../../../domain/models/cart_item.dart';
import '../../../domain/models/modifier/modifier.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_detail.dart';
import '../../../domain/models/order_status.dart';
import '../../../data/repositories/order_repository_impl.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../../domain/models/table_model.dart';
import '../../../utils/constants.dart';

class CartViewModel extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  final Map<String, OrderDetail> _orderItems = {};
  Map<String, OrderDetail> get orderItems => _orderItems;

  List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  String? _currentOrderId;
  String? _currentOrderCode;

  String? get currentOrderId => _currentOrderId;

  Map<String, CartItem> get items => _items;
  

  final _orderRepository = OrderRepositoryImpl();

  final OrderRepositoryImpl _orderRepositoryIml = OrderRepositoryImpl();
  OrderRepository get orderRepositoryIml => _orderRepositoryIml;
  
  bool _isSelectionMode = false;
  final Set<String> _selectedKeys = {};

  List<Order> _parkedOrders = [];
  List<Order> get parkedOrders => _parkedOrders;

  List<TableModel> _tables = [];
  List<TableModel> get tables => _tables;

  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedKeys => _selectedKeys;

  String _orderType = 'DINE_IN';
  int? _tableId;
  String? _tableName;

  String get orderType => _orderType;
  int? get tableId => _tableId;
  String? get tableName => _tableName;

  int? _savedTableId;
  String? _savedTableName;

  String? _currentOrderStatus;
  String? get currentOrderStatus => _currentOrderStatus;

  /// Fetches pending (parked) orders from the order repository and updates `_parkedOrders`.
  /// Notifies listeners on success; logs any error encountered.
  Future<void> fetchPendingOrders() async {
    try {
      _parkedOrders = await _orderRepository.getPendingOrders();
      notifyListeners();
    } catch (e) {
      print("Lỗi lấy đơn chờ: $e");
    }
  }

  /// Loads table data from the remote API and updates the `_tables` list.
  /// Notifies listeners on successful load; logs any error encountered.
  Future<void> fetchTables() async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/tables');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        _tables = jsonList.map((e) => TableModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Lỗi lấy bàn: $e');
    }
  }

  /// Sends a request to the server to clear the specified table, then refreshes tables.
  /// Errors are logged but not rethrown.
  Future<void> clearTable(int tableId) async {
    try {
       final uri = Uri.parse('${AppConstants.baseUrl}/tables/$tableId/clear');
       await http.put(uri);
       await fetchTables();
    } catch (e) {
       print('Lỗi dọn bàn: $e');
    }
  }

  /// Restores an existing order (by `orderId`) into the cart `_items`.
  /// Sets current order metadata (id, code, table) and recreates `CartItem`s from order details.
  /// Returns `true` on success or `false` if the order could not be loaded.
  Future<bool> restoreOrderToCart(String orderId) async {
    try {
      final fullOrder = await _orderRepository.getOrderById(orderId);
      
      if (fullOrder == null) return false;

      clearCart();

      _currentOrderId = fullOrder.id.toString();
      _currentOrderCode = fullOrder.orderCode;

      _currentOrderStatus = fullOrder.status == OrderStatus.completed ? 'COMPLETED' : 'PENDING';

      _tableId = fullOrder.tableId;
      _tableName = fullOrder.tableName;
      setOrderType(fullOrder.orderType == OrderType.dineIn ? 'DINE_IN' : 'TAKE_AWAY');

      for (var detail in fullOrder.items) {
        final tempProduct = Product(
          id: detail.productId,
          name: detail.productName,
          price: detail.price, 
          imageUrl: '',
          categoryName: '',
          categoryId: '',
          isActive: true,
        );

        final modifierIds = detail.modifiers.map((m) => m.id).toList()..sort();
        final String cartKey = '${tempProduct.id}_${modifierIds.join('_')}';

        _items[cartKey] = CartItem(
          id: detail.id,
          product: tempProduct,
          selectedModifiers: detail.modifiers,
          quantity: detail.quantity
        );
      }
      
      notifyListeners();
      _syncToSecondScreen();
      return true;
    } catch (e) {
      print("Lỗi khôi phục đơn: $e");
      return false;
    }
  }

  /// Constructs an `Order` object representing the current cart state.
  /// `userId` is set as the creator and `isPaid` controls status/payment flags.
  /// Each `CartItem` is converted into an `OrderDetail` for the returned `Order`.
  Order buildOrderObject({required String userId, required bool isPaid}) {
      final now = DateTime.now();
      
      final orderId = _currentOrderId != null ? int.parse(_currentOrderId!) : now.millisecondsSinceEpoch;
      final String orderCode = _currentOrderCode ?? '#${now.millisecondsSinceEpoch.toString().substring(8)}';
      
      List<OrderDetail> orderDetails = [];
      _items.forEach((key, cartItem) {
        orderDetails.add(OrderDetail(
          id: 'DT_${DateTime.now().microsecondsSinceEpoch}_${cartItem.product.id}',
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          price: cartItem.product.price,
          quantity: cartItem.quantity,
          totalLineAmount: cartItem.subtotal,
          modifiers: cartItem.selectedModifiers,
          note: '',
        ));
      });

      return Order(
        id: orderId,
        orderCode: orderCode,
        orderType: _orderType == 'TAKE_AWAY' ? OrderType.takeAway : OrderType.dineIn,
        tableId: _tableId,
        tableName: _tableName,
        
        status: isPaid ? OrderStatus.completed : OrderStatus.pending,
        paymentStatus: isPaid ? PaymentStatus.paid : PaymentStatus.unpaid,
        
        totalAmount: totalAmount,
        discountAmount: 0,
        taxAmount: 0,
        note: '',
        
        createdDate: now,
        createdByUserId: userId,
        items: orderDetails,
      );
    }

  /// Submits the current cart as an order (create or update) using the repository.
  /// If `isPaid` is true the cart is cleared after saving; otherwise the current order id is stored.
  /// Returns the saved `Order` on success, or `null` on failure.
  Future<Order?> submitOrder({
    required String userId, 
    required bool isPaid,
    String paymentMethod = 'CASH',
    double amountReceived = 0,
  }) async {
    
    final order = buildOrderObject(userId: userId, isPaid: isPaid);
    
    String? resultOrderId;

    if (_currentOrderId == null) {
      resultOrderId = await _orderRepository.createOrder(order);
      
      if (resultOrderId != null) {
        _currentOrderId = resultOrderId; 
      }
    } else {
      final success = await _orderRepository.updateOrder(order);
      if (success) {
        resultOrderId = _currentOrderId;
      }
    }

    if (resultOrderId != null) {
       final savedOrder = order.copyWith(id: int.parse(resultOrderId));

       if (isPaid) {
         clearCart(); 
         _currentOrderId = null;
       } else {
         _currentOrderId = resultOrderId;
         notifyListeners();
       }
       
       fetchTables();
       return savedOrder;
    }
    
    return null;
  }

  /// Calculates the total amount of the current cart by summing each item's subtotal.
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.subtotal;
    });
    return total;
  }

    /// Sets the order type (e.g., 'DINE_IN' or 'TAKE_AWAY').
    /// When switching to 'TAKE_AWAY' it clears table assignment.
    void setOrderType(String type) {
    if (_orderType == type) return;

    if (type == 'TAKE_AWAY') {
      // Trước khi chuyển sang Mang về -> Lưu lại bàn hiện tại (nếu có)
      if (_orderType == 'DINE_IN') {
        _savedTableId = _tableId;
        _savedTableName = _tableName;
      }
      // Xóa thông tin bàn trên UI
      _tableId = null;
      _tableName = null;
      
    } else if (type == 'DINE_IN') {
      // Khi quay lại Tại bàn -> Khôi phục bàn cũ (nếu có)
      if (_savedTableId != null) {
        _tableId = _savedTableId;
        _tableName = _savedTableName;
      }
    }
    
    _orderType = type;
    notifyListeners();
    _syncToSecondScreen(); // Đồng bộ ngay để màn hình khách cập nhật trạng thái
  }

  /// Assigns the given table to the current order and sets the order type to 'DINE_IN'.
  void setTable(TableModel table) {
    _tableId = table.id;
    _tableName = table.name;
    setOrderType('DINE_IN');
    _syncToSecondScreen();
    notifyListeners();
  }

  /// Toggles selection mode on/off and clears any selected item keys.
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    _selectedKeys.clear();
    notifyListeners();
  }

  /// Toggles the selection state of a cart item identified by `key`.
  void toggleItemSelection(String key) {
    if (_selectedKeys.contains(key)) {
      _selectedKeys.remove(key);
    } else {
      _selectedKeys.add(key);
    }
    notifyListeners();
  }

  /// Deletes all items currently selected (`_selectedKeys`) from the cart and exits selection mode.
  void deleteSelectedItems() {
    for (var key in _selectedKeys) {
      _items.remove(key);
    }
    _selectedKeys.clear();
    _isSelectionMode = false; 
    notifyListeners();
  }

  /// Increments the quantity of the cart item identified by `key` by 1.
  void incrementItem(String key) {
    if (_items.containsKey(key)) {
      _items.update(
        key,
        (existing) => existing.copyWith(
          quantity: existing.quantity + 1,
        ),
      );
      notifyListeners();
    }
  }

  /// Adds a `product` with optional `modifiers` to the cart. If the same product+modifiers exist,
  /// it increments the quantity; otherwise it inserts a new `CartItem`.
  void addToCart(Product product, {List<Modifier> modifiers = const []}) {
    final modifierIds = modifiers.map((m) => m.id).toList();
    modifierIds.sort();
    final String cartKey = '${product.id}_${modifierIds.join('_')}';

    if (_items.containsKey(cartKey)) {
      _items.update(
        cartKey,
        (existing) => existing.copyWith(quantity: existing.quantity + 1),
      );
    } else {
      _items.putIfAbsent(
        cartKey,
        () => CartItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          product: product,
          selectedModifiers: modifiers,
          quantity: 1,
          committedQuantity: 0,
        ),
      );
    }
    notifyListeners();
    _syncToSecondScreen();
  }

  /// Updates an existing cart item (identified by `oldKey`) to use `newModifiers`.
  /// The item is re-keyed; quantities are merged if the new key already exists.
  void updateCartItem(String oldKey, List<Modifier> newModifiers) {
    if (!_items.containsKey(oldKey)) return;

    final oldItem = _items[oldKey]!;
    final product = oldItem.product;
    final quantity = oldItem.quantity;

    _items.remove(oldKey);
    final modifierIds = newModifiers.map((m) => m.id).toList()..sort();
    final String newKey = '${product.id}_${modifierIds.join('_')}';

    if (_items.containsKey(newKey)) {
      _items.update(
        newKey,
        (existing) => existing.copyWith(quantity: existing.quantity + quantity),
      );
    } else {
      _items[newKey] = CartItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        product: product,
        selectedModifiers: newModifiers,
        quantity: quantity,
      );
    }
    notifyListeners();
  }

  /// Removes a single unit from the cart item identified by `cartKey`.
  /// If the quantity becomes zero it removes the item entirely.
  void removeSingleItem(String cartKey) {
    if (!_items.containsKey(cartKey)) return;

    if (_items[cartKey]!.quantity > 1) {
      _items.update(
        cartKey,
        (existing) => existing.copyWith(quantity: existing.quantity - 1),
      );
    } else {
      _items.remove(cartKey);
    }
    notifyListeners();
    _syncToSecondScreen();
  }

  /// Removes the entire cart row identified by `cartKey`.
  void removeCartItemRow(String cartKey) {
    _items.remove(cartKey);
    notifyListeners();
    _syncToSecondScreen();
  }

  /// Parks the given `order` (adds it to `_parkedOrders`) and clears the current cart.
  void parkOrder(Order order) {
    _parkedOrders.add(order);
    clearCart();
    notifyListeners();
  }

  /// Clears the current cart and resets current order/table metadata.
  void clearCart({bool keepTable = false}) {
      _items.clear();
      _currentOrderId = null;
      _currentOrderCode = null;
      _currentOrderStatus = null;
      
      if (!keepTable) {
        _tableId = null;
        _tableName = null;
        _savedTableId = null;
        _savedTableName = null;
      }

      notifyListeners();
      _syncToSecondScreen();
  }

  /// Starts a fresh order for the specified `table`. If a current order exists it first clears it.
  void startNewOrderForTable(TableModel table) {
    if (_currentOrderId != null) {
      clearCart();
    }
    setTable(table); 
  }

  /// Loads the given `order` into the cart `_items`, reconstructing `CartItem`s from details.
  /// Also sets table and order type, and removes the loaded order from `_parkedOrders`.
  void retrieveOrder(Order order) {
    _items.clear();

    for (var detail in order.items) {
       final product = Product(
         id: detail.productId,
         name: detail.productName,
         price: detail.price, 
         imageUrl: '',
         categoryId: '',
         categoryName: '',
         categoryImage: null,
         isActive: true,
       );

       final modifierIds = detail.modifiers.map((m) => m.id).toList()..sort();
       final String cartKey = '${product.id}_${modifierIds.join('_')}';

       _items[cartKey] = CartItem(
         id: detail.id,
         product: product,
         selectedModifiers: detail.modifiers,
         quantity: detail.quantity
       );
    }

    _tableId = order.tableId;
    _tableName = order.tableName;
    _orderType = order.orderType == OrderType.dineIn ? 'DINE_IN' : 'TAKE_AWAY';
    
    _parkedOrders.removeWhere((o) => o.id == order.id);
    
    notifyListeners();
  }

  /// Requests a kitchen reprint by incrementing the kitchen print count on the current order.
  /// Returns the new print count, or 0 if there is no current order.
  Future<int> requestReprintKitchen() async {
    if (_currentOrderId == null) return 0;
    return await _orderRepository.incrementKitchenPrintCount(_currentOrderId.toString());
  }

  /// Builds a temporary `Order` containing only the uncommitted quantities that should be printed
  /// in the kitchen (i.e., quantity - committedQuantity). Returns `null` if there is nothing to print.
Order? buildKitchenPrintOrder({required String userId}) {
    List<OrderDetail> itemsToPrint = [];

    for (var cartItem in _items.values) {
      
      int diff = cartItem.quantity - cartItem.committedQuantity;

      if (diff > 0) {
        double modifiersPrice = cartItem.selectedModifiers.fold(0, (sum, m) => sum + m.extraPrice);
        double unitPrice = cartItem.product.price + modifiersPrice;

        itemsToPrint.add(OrderDetail(
          id: '',
          productId: cartItem.product.id.toString(),
          productName: cartItem.product.name,
          price: unitPrice,
          
          quantity: diff,
          
          totalLineAmount: unitPrice * diff,
          
          modifiers: cartItem.selectedModifiers,
          
          committedQuantity: 0, 
          
          note: '',
        ));
      }
    }

    if (itemsToPrint.isEmpty) return null;

    return Order(
      id: int.tryParse(_currentOrderId ?? '0') ?? 0,
      orderCode: 'TEMP',
      createdDate: DateTime.now(),
      orderType: _orderType == 'TAKE_AWAY' ? OrderType.takeAway : OrderType.dineIn,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
      totalAmount: 0,
      
      items: itemsToPrint,
      
      kitchenPrintCount: 0,
      tableName: _tableName ?? 'Mang về', 
      createdByUserId: userId,
    );
  }

  /// Synchronizes committed quantities: copies each `_orderItems` quantity to committedQuantity,
  /// updates all cart items' committedQuantity to their current quantity, then replaces `_orderItems`.
  void syncCommittedQuantities() {
    Map<String, OrderDetail> updatedItems = {};
    
    _orderItems.forEach((key, item) {
      updatedItems[key] = item.copyWith(committedQuantity: item.quantity);
    });

    _items.updateAll((key, cartItem) {
      return cartItem.copyWith(
        committedQuantity: cartItem.quantity
      );
    });
    
    _orderItems.clear();
    _orderItems.addAll(updatedItems);
    notifyListeners();
  }

  void _syncToSecondScreen() {
    try {
      final syncData = {
        'tableName': _tableName ?? '',
        'totalAmount': totalAmount,
        'items': _items.values.map((e) => e.toJson()).toList(),
      };

      final jsonString = jsonEncode(syncData);
      
      html.window.localStorage['cart_data'] = jsonString;
      
      // print("Đã sync dữ liệu: $jsonString");
    } catch (e) {
      print("Lỗi sync: $e");
    }
  }

  double _syncedTotalAmount = 0;
  double get syncedTotalAmount => _syncedTotalAmount;

  void updateFromSyncData(dynamic jsonStringOrMap) {
    try {
      // Xử lý đầu vào: Có thể là String (từ localStorage) hoặc Map (đã decode ở main)
      Map<String, dynamic> data;
      if (jsonStringOrMap is String) {
        data = jsonDecode(jsonStringOrMap);
      } else {
        data = jsonStringOrMap;
      }

      _tableName = data['tableName'];

      _syncedTotalAmount = (data['totalAmount'] as num).toDouble();

      if (data['items'] != null) {
        final List<dynamic> itemsJson = data['items'];
        _cartItems = itemsJson.map((e) => CartItem.fromJson(e)).toList();
      } else {
        _cartItems = [];
      }

      notifyListeners(); 
      
    } catch (e) {
      print("Lỗi cập nhật dữ liệu từ sync: $e");
    }
  }

  // ... (Các code cũ giữ nguyên)

  // --- LOGIC CHUYỂN / GỘP BÀN ---

  /// Chuyển đơn hàng từ bàn hiện tại sang bàn mới (Trống)
  Future<bool> moveTable(int targetTableId) async {
    try {
      if (_currentOrderId == null) return false;

      final uri = Uri.parse('${AppConstants.baseUrl}/tables/move');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': _currentOrderId, // Đơn hàng cần chuyển
          'targetTableId': targetTableId, // Bàn đích
        }),
      );

      if (response.statusCode == 200) {
        // Chuyển thành công -> Xóa cart hiện tại để reload hoặc navigate về sơ đồ
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi chuyển bàn: $e");
      return false;
    }
  }

  /// Gộp đơn hàng từ bàn hiện tại vào bàn đích (Đang có khách)
  Future<bool> mergeTable(int targetTableId) async {
    try {
      if (_currentOrderId == null) return false;

      final uri = Uri.parse('${AppConstants.baseUrl}/tables/merge');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sourceOrderId': _currentOrderId, // Đơn hiện tại (sẽ bị hủy/gộp)
          'targetTableId': targetTableId,   // Bàn đích (đơn này sẽ nhận thêm món)
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi gộp bàn: $e");
      return false;
    }
  }
}