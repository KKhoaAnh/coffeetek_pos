import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:html' as html; // Import html để dùng LocalStorage
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

  // [FIX] 1. THÊM CONSTRUCTOR ĐỂ LẮNG NGHE SỰ KIỆN TỪ TAB KHÁC
  CartViewModel() {
    // Chỉ chạy trên Web: Lắng nghe khi LocalStorage thay đổi
    try {
      html.window.onStorage.listen((event) {
        if (event.key == 'cart_data' && event.newValue != null) {
          updateFromSyncData(event.newValue);
        }
      });
    } catch (e) {
      print("Không thể khởi tạo listener storage (có thể do không phải Web): $e");
    }
  }

  // --- LOGIC ĐỒNG BỘ MÀN HÌNH KHÁCH ---

  // [FIX] 2. Cập nhật hàm sync để thêm timestamp (ép trình duyệt nhận sự kiện)
  void _syncToSecondScreen() {
    try {
      // Chuyển đổi Map _items sang List để gửi đi
      final itemList = _items.values.map((e) => e.toJson()).toList();

      final syncData = {
        'tableName': _tableName ?? '',
        'totalAmount': totalAmount,
        'items': itemList, // Gửi danh sách món
        'timestamp': DateTime.now().millisecondsSinceEpoch, // [FIX] Quan trọng để trigger change
      };

      final jsonString = jsonEncode(syncData);
      
      // Ghi vào LocalStorage -> Tab Khách sẽ bắt được sự kiện onStorage
      html.window.localStorage['cart_data'] = jsonString;
    } catch (e) {
      print("Lỗi sync: $e");
    }
  }

  // [FIX] 3. Xử lý dữ liệu nhận được (Chạy ở Màn hình Khách)
  double _syncedTotalAmount = 0;
  double get syncedTotalAmount => _syncedTotalAmount;

  void updateFromSyncData(dynamic jsonStringOrMap) {
    try {
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
        // Cập nhật _cartItems để CustomerScreen có dữ liệu hiển thị
        _cartItems = itemsJson.map((e) => CartItem.fromJson(e)).toList();
      } else {
        _cartItems = [];
      }

      notifyListeners(); // Báo cho UI màn hình khách vẽ lại
    } catch (e) {
      print("Lỗi cập nhật dữ liệu từ sync: $e");
    }
  }


  // --- CÁC HÀM XỬ LÝ API VÀ LOGIC GIỎ HÀNG CŨ (GIỮ NGUYÊN) ---

  Future<void> fetchPendingOrders() async {
    try {
      _parkedOrders = await _orderRepository.getPendingOrders();
      notifyListeners();
    } catch (e) {
      print("Lỗi lấy đơn chờ: $e");
    }
  }

  Future<void> fetchTables() async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/tables?active_only=true');
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

  Future<void> clearTable(int tableId) async {
    try {
       final uri = Uri.parse('${AppConstants.baseUrl}/tables/$tableId/clear');
       await http.put(uri);
       await fetchTables();
    } catch (e) {
       print('Lỗi dọn bàn: $e');
    }
  }

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
      _syncToSecondScreen(); // [CHECK] Đã có sync
      return true;
    } catch (e) {
      print("Lỗi khôi phục đơn: $e");
      return false;
    }
  }

  Order buildOrderObject({
    required String userId, 
    required bool isPaid,
    // [MỚI] Thêm tham số đầu vào
    double discountAmount = 0,
    String discountType = 'NONE',
  }) {
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

      // Tính tổng tiền cuối cùng
      double finalAmount = totalAmount - discountAmount;

      return Order(
        id: orderId,
        orderCode: orderCode,
        orderType: _orderType == 'TAKE_AWAY' ? OrderType.takeAway : OrderType.dineIn,
        tableId: _tableId,
        tableName: _tableName,
        
        status: isPaid ? OrderStatus.completed : OrderStatus.pending,
        paymentStatus: isPaid ? PaymentStatus.paid : PaymentStatus.unpaid,
        
        totalAmount: totalAmount, // Tổng tiền hàng (chưa giảm)
        
        // [MỚI] Truyền thông tin giảm giá vào Model Order
        // Lưu ý: Bạn cần chắc chắn file domain/models/order.dart đã có các trường này
        discountAmount: discountAmount,
        discountType: discountType, // <-- Bỏ comment dòng này nếu Model Order đã có trường discountType
        finalAmount: finalAmount,   // <-- Bỏ comment dòng này nếu Model Order đã có trường finalAmount
        
        taxAmount: 0,
        note: '',
        
        createdDate: now,
        createdByUserId: userId,
        items: orderDetails,
      );
    }

  Future<Order?> submitOrder({
    required String userId, 
    required bool isPaid,
    String paymentMethod = 'CASH',
    double amountReceived = 0,
    double discountAmount = 0,
    String discountType = 'NONE',
  }) async {
    
    final order = buildOrderObject(userId: userId, isPaid: isPaid, discountAmount: discountAmount, discountType: discountType);
    
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
         _syncToSecondScreen(); // [CHECK] Thêm sync sau khi lưu đơn
       }
       
       fetchTables();
       return savedOrder;
    }
    
    return null;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.subtotal;
    });
    return total;
  }

  void setOrderType(String type) {
    if (_orderType == type) return;

    if (type == 'TAKE_AWAY') {
      if (_orderType == 'DINE_IN') {
        _savedTableId = _tableId;
        _savedTableName = _tableName;
      }
      _tableId = null;
      _tableName = null;
      
    } else if (type == 'DINE_IN') {
      if (_savedTableId != null) {
        _tableId = _savedTableId;
        _tableName = _savedTableName;
      }
    }
    
    _orderType = type;
    notifyListeners();
    _syncToSecondScreen(); // [CHECK] Đã có sync
  }

  void setTable(TableModel table) {
    _tableId = table.id;
    _tableName = table.name;
    setOrderType('DINE_IN');
    _syncToSecondScreen(); // [CHECK] Đã có sync
    notifyListeners();
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    _selectedKeys.clear();
    notifyListeners();
  }

  void toggleItemSelection(String key) {
    if (_selectedKeys.contains(key)) {
      _selectedKeys.remove(key);
    } else {
      _selectedKeys.add(key);
    }
    notifyListeners();
  }

  void deleteSelectedItems() {
    for (var key in _selectedKeys) {
      _items.remove(key);
    }
    _selectedKeys.clear();
    _isSelectionMode = false; 
    notifyListeners();
    _syncToSecondScreen(); // [FIX] Thêm sync khi xóa nhiều món
  }

  void incrementItem(String key) {
    if (_items.containsKey(key)) {
      _items.update(
        key,
        (existing) => existing.copyWith(
          quantity: existing.quantity + 1,
        ),
      );
      notifyListeners();
      _syncToSecondScreen(); // [FIX] Thêm sync khi tăng số lượng
    }
  }

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
    _syncToSecondScreen(); // [CHECK] Đã có sync
  }

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
    _syncToSecondScreen(); // [FIX] Thêm sync khi update món
  }

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
    _syncToSecondScreen(); // [CHECK] Đã có sync
  }

  void removeCartItemRow(String cartKey) {
    _items.remove(cartKey);
    notifyListeners();
    _syncToSecondScreen(); // [CHECK] Đã có sync
  }

  void parkOrder(Order order) {
    _parkedOrders.add(order);
    clearCart();
    notifyListeners();
  }

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
      _syncToSecondScreen(); // [CHECK] Đã có sync
  }

  void startNewOrderForTable(TableModel table) {
    if (_currentOrderId != null) {
      clearCart();
    }
    setTable(table); 
  }

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
    _syncToSecondScreen(); // [FIX] Thêm sync khi nạp lại đơn chờ
  }

  Future<int> requestReprintKitchen() async {
    if (_currentOrderId == null) return 0;
    return await _orderRepository.incrementKitchenPrintCount(_currentOrderId.toString());
  }

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

  // --- LOGIC CHUYỂN / GỘP BÀN ---

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
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi chuyển bàn: $e");
      return false;
    }
  }

  Future<bool> mergeTable(int targetTableId) async {
    try {
      if (_currentOrderId == null) return false;

      final uri = Uri.parse('${AppConstants.baseUrl}/tables/merge');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sourceOrderId': _currentOrderId,
          'targetTableId': targetTableId, 
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