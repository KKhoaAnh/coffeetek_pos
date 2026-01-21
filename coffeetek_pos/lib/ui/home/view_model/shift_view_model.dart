import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../utils/constants.dart'; // Nơi chứa AppConstants.baseUrl
import '../../../domain/models/shift_model.dart';

class ShiftViewModel extends ChangeNotifier {
  List<ShiftModel> _todayShifts = []; // Danh sách ca hôm nay
  bool _isLoading = false;
  
  List<ShiftModel> get todayShifts => _todayShifts;
  bool get isLoading => _isLoading;

  // Lấy ca đang mở (nếu có) - Là ca đầu tiên trong list nếu status = OPEN
  ShiftModel? get currentOpenShift {
    if (_todayShifts.isNotEmpty && _todayShifts.first.isOpen) {
      return _todayShifts.first;
    }
    return null;
  }

  bool get hasOpenShift => currentOpenShift != null;

  Future<void> loadTodayShifts(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Gọi API mới: /today
      final uri = Uri.parse('${AppConstants.baseUrl}/shifts/today?userId=$userId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _todayShifts = data.map((json) => ShiftModel.fromJson(json)).toList();
      } else {
        _todayShifts = [];
      }
    } catch (e) {
      print("Lỗi load ca: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, double>?> getShiftSummary() async {
    if (!hasOpenShift) return null;
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/shifts/summary?shiftId=${currentOpenShift!.id}');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // [FIX LỖI TYPE ERROR TẠI ĐÂY]
        // Thay vì ép kiểu (data['...'] as num).toDouble() -> Cách này chết khi gặp String
        // Ta dùng: double.tryParse(data['...'].toString()) -> Cách này cân tất cả (String, Int, Double)
        return {
          'initial': double.tryParse(data['initial_float'].toString()) ?? 0.0,
          'sales': double.tryParse(data['total_cash_sales'].toString()) ?? 0.0,
          'expected': double.tryParse(data['expected_cash'].toString()) ?? 0.0,
        };
      }
    } catch (e) {
      print("Lỗi lấy summary: $e");
    }
    return null;
  }

  // 2. Mở ca
  Future<bool> openShift(int userId, double initialFloat, String note) async {
    _isLoading = true;
    notifyListeners();
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/shifts/open');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'initial_float': initialFloat,
          'note': note // Gửi note
        }),
      );
      if (response.statusCode == 201) {
        await loadTodayShifts(userId); 
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> closeShift(double actualCash, String note) async {
    if (!hasOpenShift) return null;
    
    final int userId = currentOpenShift!.userId;
    final int shiftId = currentOpenShift!.id;
    final String currentUserName = currentOpenShift!.userName; // Lấy tên để in

    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/shifts/close');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'shift_id': shiftId,
          'actual_cash': actualCash,
          'note': note
        }),
      );

      if (response.statusCode == 200) {
        await loadTodayShifts(userId); 
        
        // Trả về dữ liệu server gửi về để in phiếu Z-Report
        final resData = jsonDecode(response.body);
        final data = resData['data'];
        
        // Gán lại tên user vào data để in (vì server có thể không trả về tên)
        data['user_name'] = currentUserName; 
        
        return data;
      }
      return null;
    } catch (e) {
      print("Exception closeShift: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}