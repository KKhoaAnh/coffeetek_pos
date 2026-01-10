import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';
import '../../utils/constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class MenuService {
  final String _baseUrl = '${AppConstants.baseUrl}/products';
  final String _uploadUrl = '${AppConstants.baseUrl}/upload';

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Category>> getAllCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await http.post(Uri.parse(_baseUrl),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(Uri.parse('$_baseUrl/$id'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(data));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> toggleStatus(String id, bool isActive) async {
    try {
      final response = await http.patch(Uri.parse('$_baseUrl/$id/status'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode({'is_active': isActive}));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<String?> uploadImage(XFile imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      var bytes = await imageFile.readAsBytes();
      
      var multipartFile = http.MultipartFile.fromBytes(
        'image', 
        bytes,
        filename: imageFile.name,
      );

      request.files.add(multipartFile);

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var json = jsonDecode(responseData.body);
        return json['filename'];
      }
      return null;
    } catch (e) {
      print("Lỗi upload: $e");
      return null;
    }
  }

  Future<List<String>> getProductModifierIds(String productId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$productId/modifier-ids'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}