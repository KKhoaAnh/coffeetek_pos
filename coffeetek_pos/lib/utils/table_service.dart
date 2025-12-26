import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import '../../domain/models/table_model.dart';

class TableService {
  Future<List<TableModel>> getTables() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/tables'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TableModel.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi tải danh sách bàn: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tables: $e');
      return [];
    }
  }

  Future<bool> updatePositions(List<TableModel> tables) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/tables/positions');
      
      // Convert List<TableModel> -> List<Map> -> JSON String
      final body = jsonEncode(tables.map((t) => t.toJson()).toList());

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi lưu vị trí bàn: $e");
      return false;
    }
  }
}