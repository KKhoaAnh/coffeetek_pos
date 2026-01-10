import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/modifier/modifier_group.dart';
import '../../utils/constants.dart';

class ModifierService {
  final String _baseUrl = '${AppConstants.baseUrl}/modifiers';

  Future<List<ModifierGroup>> getAllModifiers() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ModifierGroup.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createGroup(String name, bool isMulti, bool isRequired) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/group'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'group_name': name,
          'is_multi_select': isMulti,
          'is_required': isRequired
        }),
      );
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  Future<bool> createModifier(String name, String groupId, double price, bool allowInput) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/item'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'modifier_name': name,
          'group_id': groupId,
          'extra_price': price,
          'is_input_required': allowInput
        }),
      );
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  Future<bool> updateModifier(String id, String name, double price, bool allowInput) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/item/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'modifier_name': name,
          'extra_price': price,
          'is_input_required': allowInput
        }),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> deleteModifier(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/item/$id'));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }
}