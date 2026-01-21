import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../data/model/product_api_model.dart';
import '../../utils/constants.dart';
import '../../domain/models/modifier/modifier_group.dart';
import '../../data/model/modifier_api_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final String _baseUrl = '${AppConstants.baseUrl}/products';
  @override
  Future<List<Product>> getProducts() async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/products');
      print('GET Request: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        
        return jsonList.map((json) {
          return ProductApiModel.fromJson(json).toDomain();
        }).toList();
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi gọi API Get Products: $e');
      throw Exception('Không thể kết nối đến máy chủ: $e');
    }
  }

  @override
  Future<List<ModifierGroup>> getProductModifiers(String productId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$productId/modifiers'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map((json) {
          return ModifierGroup.fromJson(json);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    throw UnimplementedError();
  }
}