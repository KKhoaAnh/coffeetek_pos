import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State Filter
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _dateLabel = "Hôm nay";

  // Data State
  Map<String, dynamic> _summaryData = {};
  List<dynamic> _categoryData = [];
  List<dynamic> _productData = [];
  bool _isLoading = false;

  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchReports();
  }

  // --- LOGIC GỌI API ---
  Map<String, double> _calculateTotals(List<dynamic> data) {
    double totalQty = 0;
    double totalRev = 0;
    for (var item in data) {
      totalQty += double.tryParse(item['total_quantity'].toString()) ?? 0;
      totalRev += double.tryParse(item['total_revenue'].toString()) ?? 0;
    }
    return {'qty': totalQty, 'rev': totalRev};
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
    final query = "?startDate=$startStr&endDate=$endStr";

    try {
      // Gọi song song 3 API để tiết kiệm thời gian
      final responses = await Future.wait([
        http.get(Uri.parse('${AppConstants.baseUrl}/reports/summary$query')),
        http.get(Uri.parse('${AppConstants.baseUrl}/reports/category$query')),
        http.get(Uri.parse('${AppConstants.baseUrl}/reports/product$query')),
      ]);

      if (responses[0].statusCode == 200) {
        setState(() {
          _summaryData = jsonDecode(responses[0].body);
          _categoryData = jsonDecode(responses[1].body);
          _productData = jsonDecode(responses[2].body);
        });
      }
    } catch (e) {
      print("Lỗi tải báo cáo: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIC CHỌN NGÀY ---
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.brown,
            colorScheme: ColorScheme.light(primary: Colors.brown),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _dateLabel = "${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}";
      });
      _fetchReports();
    }
  }

  void _setQuickDate(int daysAgo, String label) {
    final now = DateTime.now();
    setState(() {
      if (daysAgo == 0) { // Hôm nay
        _startDate = now;
        _endDate = now;
      } else if (daysAgo == 1) { // Hôm qua
        _startDate = now.subtract(const Duration(days: 1));
        _endDate = now.subtract(const Duration(days: 1));
      } else { // 7 ngày, 30 ngày
        _startDate = now.subtract(Duration(days: daysAgo));
        _endDate = now;
      }
      _dateLabel = label;
    });
    _fetchReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("BÁO CÁO DOANH THU", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          tabs: const [
            Tab(text: "TỔNG HỢP"),
            Tab(text: "THEO NHÓM"),
            Tab(text: "CHI TIẾT MÓN"),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. FILTER BAR (Thanh lọc ngày)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                _buildQuickFilterBtn("Hôm nay", 0),
                const SizedBox(width: 8),
                _buildQuickFilterBtn("Hôm qua", 1),
                const SizedBox(width: 8),
                _buildQuickFilterBtn("7 ngày", 7),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month, color: Colors.brown),
                  label: Text(_dateLabel, style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    side: const BorderSide(color: Colors.brown),
                  ),
                  onPressed: _selectDateRange,
                )
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // 2. MAIN CONTENT
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.brown))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildCategoryTab(),
                    _buildProductTab(),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: TỔNG HỢP ---
  Widget _buildSummaryTab() {
    double totalRevenue = double.tryParse(_summaryData['total_sales']?.toString() ?? '0') ?? 0;
    double totalDiscount = double.tryParse(_summaryData['total_discount']?.toString() ?? '0') ?? 0;
    double netRevenue = double.tryParse(_summaryData['net_revenue']?.toString() ?? '0') ?? 0;
    int totalOrders = int.tryParse(_summaryData['total_orders']?.toString() ?? '0') ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildBigCard("DOANH THU THỰC", currencyFormat.format(netRevenue), Icons.attach_money, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildBigCard("TỔNG ĐƠN HÀNG", "$totalOrders đơn", Icons.receipt_long, Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoCard("Tổng tiền hàng", currencyFormat.format(totalRevenue), Colors.grey[700]!)),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoCard("Tổng giảm giá", "-${currencyFormat.format(totalDiscount)}", Colors.red[700]!)),
            ],
          ),
          
          const SizedBox(height: 30),
          // Có thể thêm Biểu đồ ở đây sau này
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text("Biểu đồ doanh thu...", style: TextStyle(color: Colors.grey))),
          )
        ],
      ),
    );
  }

  // --- TAB 2: THEO NHÓM ---
  Widget _buildCategoryTab() {
    if (_categoryData.isEmpty) return const Center(child: Text("Chưa có dữ liệu."));

    final totals = _calculateTotals(_categoryData);

    return Column(
      children: [
        // PHẦN 1: BẢNG DỮ LIỆU (CUỘN ĐƯỢC)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.brown[50]),
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text("Tên Nhóm", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Số lượng", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Doanh thu", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  // Chỉ hiển thị dữ liệu, KHÔNG thêm dòng tổng vào đây nữa
                  rows: _categoryData.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item['category_name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text("${item['total_quantity']}")),
                      DataCell(Text(currencyFormat.format(double.parse(item['total_revenue'].toString())), style: const TextStyle(color: Colors.brown))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),

        // PHẦN 2: CHÂN TRANG CỐ ĐỊNH (STICKY FOOTER)
        _buildStickyFooter(
          totalQty: totals['qty']!, 
          totalRev: totals['rev']!
        ),
      ],
    );
  }

  // --- TAB 3: CHI TIẾT MÓN ---
  Widget _buildProductTab() {
    if (_productData.isEmpty) return const Center(child: Text("Chưa có dữ liệu."));

    final totals = _calculateTotals(_productData);

    return Column(
      children: [
        // PHẦN 1: SCROLLABLE LIST
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.brown[50]),
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text("Tên Món", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Nhóm", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("SL", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Doanh thu", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _productData.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(item['category_name'])),
                      DataCell(Text("${item['total_quantity']}")),
                      DataCell(Text(currencyFormat.format(double.parse(item['total_revenue'].toString())), style: const TextStyle(color: Colors.brown))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),

        // PHẦN 2: STICKY FOOTER
        _buildStickyFooter(
          totalQty: totals['qty']!, 
          totalRev: totals['rev']!
        ),
      ],
    );
  }

  Widget _buildStickyFooter({required double totalQty, required double totalRev}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4), // Bóng đổ ngược lên trên
            blurRadius: 10,
          )
        ],
        border: const Border(top: BorderSide(color: Colors.brown, width: 3)), // Viền trên màu nâu đậm tạo điểm nhấn
      ),
      child: SafeArea( // Đảm bảo không bị che bởi nút Home trên iPhone đời mới
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "TỔNG CỘNG",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.brown, letterSpacing: 1),
            ),
            
            // Hiển thị tổng hợp gọn gàng
            Row(
              children: [
                _buildFooterItem("Số lượng", "${totalQty.toInt()}", Colors.black87),
                const SizedBox(width: 20),
                Container(width: 1, height: 30, color: Colors.grey[300]), // Đường kẻ dọc ngăn cách
                const SizedBox(width: 20),
                _buildFooterItem("Doanh thu", currencyFormat.format(totalRev), Colors.red[700]!),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFooterItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  // --- CÁC WIDGET CON (UI COMPONENTS) ---

  Widget _buildDataTable({required List<String> columns, required List<DataRow> rows}) {
    if (rows.isEmpty) return const Center(child: Text("Chưa có dữ liệu trong khoảng thời gian này."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.brown[50]),
            dataRowHeight: 60,
            columnSpacing: 20,
            columns: columns.map((c) => DataColumn(
              label: Text(c, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[900], fontSize: 15))
            )).toList(),
            rows: rows,
          ),
        ),
      ),
    );
  }

  Widget _buildBigCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
              Icon(icon, color: color.withOpacity(0.5), size: 24)
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!)
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickFilterBtn(String label, int days) {
    // Logic đơn giản để check active (chưa hoàn hảo, nhưng đủ dùng demo)
    bool isActive = false;
    final now = DateTime.now();
    if (days == 0 && _startDate.day == now.day && _endDate.day == now.day) isActive = true;

    return ElevatedButton(
      onPressed: () => _setQuickDate(days, label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.brown : Colors.white,
        foregroundColor: isActive ? Colors.white : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isActive ? Colors.brown : Colors.grey[300]!)
        )
      ),
      child: Text(label),
    );
  }
}