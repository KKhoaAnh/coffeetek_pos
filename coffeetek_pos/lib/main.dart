import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/auth/view_model/auth_view_model.dart';
import 'ui/auth/widgets/login_screen.dart';
import 'data/repositories/product_repository_impl.dart';
import 'domain/usecases/get_products_usecase.dart';
import 'ui/home/view_model/pos_view_model.dart';
import 'ui/home/view_model/cart_view_model.dart';
import 'ui/home/widgets/table_screen.dart';
import 'ui/customer_display/customer_screen.dart';
import 'ui/manager/manager_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (html.window.location.hash.contains('/customer')) {
    runApp(const CustomerApp());
  } else {
    runApp(const CoffeeTekApp());
  }
}

class CoffeeTekApp extends StatelessWidget {
  const CoffeeTekApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productRepository = ProductRepositoryImpl();
    final getProductsUseCase = GetProductsUseCase(productRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => PosViewModel(getProductsUseCase)),
        // CartViewModel ở đây là instance của màn hình Thu ngân
        ChangeNotifierProvider(create: (_) => CartViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CoffeeTek POS',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          scaffoldBackgroundColor: Colors.grey[100],
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: Consumer<AuthViewModel>(
          builder: (context, authVM, _) {
            if (authVM.isAuthenticated) {
              final user = authVM.currentUser;
                if (user != null && (user.role == 'admin' || user.role == 'manager')) {
                return const ManagerDashboardScreen();
              }
                return const TableScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

// --- ỨNG DỤNG CHO KHÁCH HÀNG (DISPLAY) ---
class CustomerApp extends StatefulWidget {
  const CustomerApp({Key? key}) : super(key: key);

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  // Tạo CartViewModel riêng cho màn hình khách
  final CartViewModel _customerCartVM = CartViewModel();

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  void _setupListener() {
    final initialData = html.window.localStorage['cart_data'];
    if (initialData != null) {
      _updateCartFromJSON(initialData);
    }

    html.window.addEventListener('storage', (event) {
      if (event is html.StorageEvent && event.key == 'cart_data') {
        if (event.newValue != null) {
          _updateCartFromJSON(event.newValue!);
        }
      }
    });
  }

  void _updateCartFromJSON(String jsonString) {
    try {
      final dynamic data = jsonDecode(jsonString);
      
      _customerCartVM.updateFromSyncData(data);
      
    } catch (e) {
      print("Lỗi parse data main.dart: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _customerCartVM),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Customer Display',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          useMaterial3: true,
        ),
        initialRoute: '/customer', 
        routes: {
          '/customer': (context) => const CustomerScreen(),
        },
      ),
    );
  }
}