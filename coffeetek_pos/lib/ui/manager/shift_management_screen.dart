import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../auth/view_model/auth_view_model.dart';
import '../home/view_model/shift_view_model.dart';
import '../../domain/models/shift_model.dart';
import '../../utils/printer_service.dart';
import '../home/widgets/table_screen.dart';

class ShiftManagementScreen extends StatelessWidget {
  const ShiftManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShiftViewModel(),
      child: const _ShiftScreenContent(),
    );
  }
}

class _ShiftScreenContent extends StatefulWidget {
  const _ShiftScreenContent({Key? key}) : super(key: key);

  @override
  State<_ShiftScreenContent> createState() => _ShiftScreenContentState();
}

class _ShiftScreenContentState extends State<_ShiftScreenContent> {
  Timer? _timer;
  String _elapsedTime = "00:00:00";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthViewModel>(context, listen: false).currentUser;
      if (user != null) {
        Provider.of<ShiftViewModel>(context, listen: false).loadTodayShifts(int.parse(user.id));
      }
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // [FIX LỖI 7:00:00]: Tự tính toán giờ/phút/giây thay vì dùng DateTime formatting
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final shiftVM = Provider.of<ShiftViewModel>(context, listen: false);
      if (shiftVM.hasOpenShift) {
        final start = shiftVM.currentOpenShift!.startTime;
        final now = DateTime.now();
        final duration = now.difference(start); // Chênh lệch thời gian thực
        
        if (mounted) {
          setState(() {
            _elapsedTime = _formatDuration(duration);
          });
        }
      } else {
        if (_elapsedTime != "00:00:00") setState(() => _elapsedTime = "00:00:00");
      }
    });
  }

  String _formatDuration(Duration duration) {
    // Nếu giờ điện thoại chậm hơn giờ Server -> duration bị âm
    if (duration.isNegative) {
      return "00:00:00"; 
    }
    
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final shiftVM = Provider.of<ShiftViewModel>(context);
    final user = Provider.of<AuthViewModel>(context).currentUser;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("QUẢN LÝ CA LÀM VIỆC", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.brown,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: shiftVM.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CỘT TRÁI: DANH SÁCH CA HÔM NAY ---
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "LỊCH SỬ CA HÔM NAY (${DateFormat('dd/MM').format(DateTime.now())})",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 10),
                        
                        Expanded(
                          child: shiftVM.todayShifts.isEmpty 
                            ? _buildEmptyState() 
                            : ListView.builder(
                                itemCount: shiftVM.todayShifts.length,
                                itemBuilder: (ctx, i) {
                                  final shift = shiftVM.todayShifts[i];
                                  return _buildShiftItem(shift, currencyFormat);
                                },
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),
                  
                  // --- CỘT PHẢI: HÀNH ĐỘNG ---
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Card Trạng Thái & Hành Động
                        Card(
                          elevation: 6,
                          color: shiftVM.hasOpenShift ? Colors.red[50] : Colors.green[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: InkWell(
                            onTap: () {
                              if (shiftVM.hasOpenShift) {
                                _showCloseShiftDialog(context, shiftVM);
                              } else {
                                _showOpenShiftDialog(context, shiftVM, user!.id);
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 300,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Hiển thị đồng hồ to nếu đang mở
                                  if (shiftVM.hasOpenShift) ...[
                                    const Text("CA ĐANG HOẠT ĐỘNG", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 10),
                                    Text(
                                      _elapsedTime,
                                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  
                                  Icon(
                                    shiftVM.hasOpenShift ? Icons.stop_circle_outlined : Icons.play_circle_fill,
                                    size: 80,
                                    color: shiftVM.hasOpenShift ? Colors.red : Colors.green,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    shiftVM.hasOpenShift ? "KẾT THÚC CA" : "MỞ CA MỚI",
                                    style: TextStyle(
                                      fontSize: 24, 
                                      fontWeight: FontWeight.w900, 
                                      color: shiftVM.hasOpenShift ? Colors.red[900] : Colors.green[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("Chưa có ca nào hôm nay", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildShiftItem(ShiftModel shift, NumberFormat currency) {
    bool isOpen = shift.isOpen;
    
    return Card(
      elevation: isOpen ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOpen ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- HÀNG 1: TRẠNG THÁI & GIỜ ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isOpen ? Icons.timer : Icons.check_circle, 
                      color: isOpen ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOpen ? "ĐANG MỞ" : "ĐÃ ĐÓNG",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOpen ? Colors.green[700] : Colors.grey[700]
                          ),
                        ),
                        Text(shift.userName, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
                      ],
                    ),
                  ],
                ),
                
                // Giờ bắt đầu - Kết thúc
                Text(
                  "${DateFormat('HH:mm').format(shift.startTime)} - ${shift.endTime != null ? DateFormat('HH:mm').format(shift.endTime!) : '...'}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                )
              ],
            ),
            
            const Divider(height: 20),

            // --- HÀNG 2: THÔNG TIN & NÚT IN ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Thông tin tiền
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMiniInfo("Tiền đầu ca", currency.format(shift.initialFloat)),
                    if (!isOpen) ...[
                      const SizedBox(height: 4),
                      _buildMiniInfo("Doanh thu TM", currency.format(shift.totalCashSales)),
                    ]
                  ],
                ),

                // Nút hành động
                if (isOpen) 
                  const Text("Đang hoạt động...", style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic, fontSize: 12))
                else
                  // [MỚI] Nút In lại cho ca đã đóng
                  TextButton.icon(
                    onPressed: () => _reprintReport(shift), // Gọi hàm in
                    icon: const Icon(Icons.print, size: 18, color: Colors.brown),
                    label: const Text("In phiếu", style: TextStyle(color: Colors.brown)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.brown.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  // Dialog Mở/Đóng giữ nguyên logic cũ nhưng gọi hàm ViewModel mới
  void _showOpenShiftDialog(BuildContext context, ShiftViewModel vm, String userId) {
      final moneyCtrl = TextEditingController();
      final noteCtrl = TextEditingController(); // [MỚI]

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("MỞ CA MỚI"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: moneyCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(labelText: "Tiền đầu ca (VNĐ)", suffixText: "đ"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: "Ghi chú (Tùy chọn)", hintText: "Ví dụ: Két thiếu 10k..."),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () async {
                double val = double.tryParse(moneyCtrl.text) ?? 0;
                
                // Gọi hàm mở ca
                bool success = await vm.openShift(int.parse(userId), val, noteCtrl.text);
                
                if (context.mounted) {
                  Navigator.pop(ctx); // 1. Đóng hộp thoại mở ca
                  
                  if (success) {
                    // 2. Chuyển ngay sang màn hình Bán hàng (TableScreen)
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const TableScreen())
                    );
                    
                    // Hoặc nếu muốn xóa lịch sử back để không quay lại màn hình quản lý:
                    // Navigator.pushAndRemoveUntil(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const TableScreen()),
                    //   (route) => false // Điều kiện giữ lại route cũ (false là xóa hết)
                    // );
                  }
                }
              },
              child: const Text("MỞ CA"),
            )
          ],
        ),
      );
  }

  // Dialog Đóng Ca & Đối Soát (Reconciliation)
  // Hàm hiển thị Dialog Đóng Ca & Đối Soát (Phiên bản đầy đủ)
  void _showCloseShiftDialog(BuildContext context, ShiftViewModel vm) async {
    // 1. Hiển thị loading trong lúc lấy số liệu từ Server
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 2. Lấy số liệu tóm tắt từ Server
    final summary = await vm.getShiftSummary();
    
    // Tắt loading nếu màn hình vẫn còn đó
    if (context.mounted) Navigator.pop(context); 

    if (summary == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi lấy dữ liệu ca!")));
      return;
    }

    // 3. Chuẩn bị các Controller và Format
    final actualCashCtrl = TextEditingController();
    final noteCtrl = TextEditingController(); // [BỔ SUNG] Controller cho ghi chú
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // Biến tạm để tính chênh lệch ngay trên UI (Reactive)
    final ValueNotifier<double> differenceNotifier = ValueNotifier(0 - summary['expected']!);

    // 4. Hiển thị Dialog chốt ca
    if (!context.mounted) return; // Kiểm tra an toàn
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: const [
            Icon(Icons.assignment_turned_in, color: Colors.brown),
            SizedBox(width: 10),
            Text("ĐỐI SOÁT & ĐÓNG CA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PHẦN 1: SỐ LIỆU HỆ THỐNG ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      _buildSummaryRow("Tiền đầu ca:", summary['initial']!, currency),
                      const SizedBox(height: 8),
                      _buildSummaryRow("Doanh thu tiền mặt:", summary['sales']!, currency, isBold: true),
                      const Divider(),
                      _buildSummaryRow("Hệ thống tính (Expected):", summary['expected']!, currency, isHighlight: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- PHẦN 2: NHẬP THỰC TẾ ---
                const Text("Tiền thực tế trong két (Actual):", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: actualCashCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    suffixText: 'đ',
                    hintText: 'Nhập số tiền bạn đếm được...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  ),
                  onChanged: (val) {
                    double actual = double.tryParse(val) ?? 0;
                    differenceNotifier.value = actual - summary['expected']!;
                  },
                ),

                const SizedBox(height: 20),

                // --- PHẦN 3: HIỂN THỊ CHÊNH LỆCH (LIVE) ---
                ValueListenableBuilder<double>(
                  valueListenable: differenceNotifier,
                  builder: (context, diff, child) {
                    Color diffColor = diff == 0 ? Colors.green : (diff < 0 ? Colors.red : Colors.blue);
                    String statusText = diff == 0 ? "Khớp" : (diff < 0 ? "Thiếu" : "Thừa");
                    
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: diffColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: diffColor)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Chênh lệch ($statusText):", style: TextStyle(color: diffColor, fontWeight: FontWeight.bold)),
                          Text(currency.format(diff), style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // --- [BỔ SUNG] PHẦN 4: GHI CHÚ ĐÓNG CA ---
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ghi chú đóng ca",
                    hintText: "Nhập lý do chênh lệch hoặc bàn giao...",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy bỏ")),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              // 1. Lấy dữ liệu nhập
              double actual = double.tryParse(actualCashCtrl.text) ?? 0;
              
              // 2. Kiểm tra chênh lệch lớn (Optional Warning)
              double diff = actual - summary['expected']!;
              if (diff.abs() > 500000) { 
                 // Có thể thêm Dialog cảnh báo phụ ở đây nếu muốn
              }

              // 3. Gọi hàm đóng ca (Gửi thêm Note)
              final printData = await vm.closeShift(actual, noteCtrl.text);
              
              if(context.mounted) {
                 Navigator.pop(ctx); // Đóng Dialog chính
                 
                 if (printData != null) {
                    // Thành công -> Thông báo & In phiếu
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Đóng ca thành công! Đang in phiếu kết ca..."),
                      backgroundColor: Colors.green,
                    ));
                    
                    // [BỔ SUNG] Gọi Printer Service
                    try {
                      final printer = PrinterService();
                      await printer.printShiftReport(printData);
                    } catch (e) {
                      print("Lỗi in ấn: $e");
                    }

                 } else {
                    // Thất bại
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Có lỗi xảy ra khi đóng ca!"),
                      backgroundColor: Colors.red,
                    ));
                 }
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Text("XÁC NHẬN & IN PHIẾU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, NumberFormat fmt, {bool isBold = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700])),
        Text(
          fmt.format(value), 
          style: TextStyle(
            fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.normal,
            fontSize: isHighlight ? 16 : 14,
            color: isHighlight ? Colors.brown : Colors.black
          )
        ),
      ],
    );
  }

  void _reprintReport(ShiftModel shift) async {
    try {
      // Hiển thị loading nhẹ
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang xử lý in..."), duration: Duration(seconds: 1)));

      // Chuẩn bị dữ liệu Map để gửi sang PrinterService
      // Vì ta đã cập nhật ShiftModel ở Bước A nên dữ liệu đã có sẵn, không cần gọi API nữa
      final reportData = {
        'user_name': shift.userName,
        'start_time': shift.startTime.toString(),
        'end_time': shift.endTime.toString(),
        'initial_float': shift.initialFloat,
        'total_cash_sales': shift.totalCashSales,
        'expected_cash': shift.expectedCash,
        'actual_cash': shift.actualCash,
        'difference': shift.difference,
        'note': shift.note ?? ''
      };

      final printer = PrinterService();
      await printer.printShiftReport(reportData);
      
    } catch (e) {
      print("Lỗi in lại: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi in phiếu!"), backgroundColor: Colors.red));
    }
  }
}