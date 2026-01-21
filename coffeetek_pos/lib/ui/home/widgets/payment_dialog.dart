import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  // [CẬP NHẬT] Callback trả về thêm thông tin giảm giá để lưu vào Order
  final Function(String paymentMethod, double amountReceived, double discountAmount, String discountType) onConfirm;

  const PaymentDialog({
    Key? key,
    required this.totalAmount,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _selectedMethod = 'CASH';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customDiscountController = TextEditingController();
  
  double _amountReceived = 0;
  double _changeAmount = 0;

  // --- STATE KHUYẾN MÃI ---
  String _discountType = 'NONE'; // 'NONE', 'AMOUNT', 'PERCENT'
  double _discountValue = 0;     // Giá trị nhập vào (vnđ hoặc %)
  double _finalTotal = 0;        // Tổng tiền sau khi trừ khuyến mãi

  @override
  void initState() {
    super.initState();
    _finalTotal = widget.totalAmount;
    _amountReceived = _finalTotal;
    _amountController.text = NumberFormat('#,###', 'vi_VN').format(_amountReceived);
  }

  // --- LOGIC TÍNH TOÁN ---
  void _calculateValues() {
    double discountAmount = 0;

    // 1. Tính giá trị giảm giá thực tế
    if (_discountType == 'AMOUNT') {
      discountAmount = _discountValue;
    } else if (_discountType == 'PERCENT') {
      discountAmount = widget.totalAmount * (_discountValue / 100);
    }

    // Validate: Không giảm quá tổng tiền
    if (discountAmount > widget.totalAmount) discountAmount = widget.totalAmount;

    // 2. Tính tổng tiền cuối cùng khách phải trả
    double newFinalTotal = widget.totalAmount - discountAmount;

    setState(() {
      _finalTotal = newFinalTotal;
      // Recalculate tiền thừa dựa trên tổng tiền MỚI
      _changeAmount = _amountReceived - _finalTotal;
    });
  }

  void _updateAmountReceived(double amount) {
    setState(() {
      _amountReceived = amount;
      _changeAmount = _amountReceived - _finalTotal;
      _amountController.text = NumberFormat('#,###', 'vi_VN').format(_amountReceived);
    });
  }

  void _setDiscount(String type, double value) {
    setState(() {
      _discountType = type;
      _discountValue = value;
      // Reset input custom nếu chọn preset
      if (type == 'NONE') {
         _customDiscountController.clear();
      }
    });
    _calculateValues();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final numberFormat = NumberFormat('#,###', 'vi_VN');

    // Gợi ý tiền mặt thông minh dựa trên FINAL TOTAL
    final smartSuggestions = _getSmartSuggestions(_finalTotal);
    final hardDenominations = [500000.0, 200000.0, 100000.0, 50000.0];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 900, // [CẬP NHẬT] Mở rộng kích thước Dialog
        height: 750,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("THANH TOÁN & KHUYẾN MÃI", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
              ],
            ),
            const Divider(height: 30),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================
                  // CỘT TRÁI: THÔNG TIN & KM
                  // ==========================
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        // 1. TỔNG TIỀN GỐC
                        _buildInfoRow("Tổng tiền hàng:", currencyFormat.format(widget.totalAmount), isBold: false),
                        const SizedBox(height: 10),
                        
                        // 2. KHU VỰC CHỌN KHUYẾN MÃI (ACCORDION STYLE)
                        _buildDiscountSection(currencyFormat),

                        const Spacer(),
                        const Divider(),
                        
                        // 3. TỔNG THANH TOÁN (FINAL)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.brown[50], borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("KHÁCH CẦN TRẢ:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                              Text(
                                currencyFormat.format(_finalTotal),
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(width: 1, height: double.infinity, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 24)),

                  // ==========================
                  // CỘT PHẢI: PHƯƠNG THỨC & TIỀN
                  // ==========================
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        // 1. CHỌN PHƯƠNG THỨC
                        Row(
                          children: [
                            Expanded(child: _buildMethodBtn('CASH', 'TIỀN MẶT', Icons.money)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildMethodBtn('TRANSFER', 'CHUYỂN KHOẢN', Icons.qr_code)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 2. NHẬP TIỀN KHÁCH ĐƯA (Chỉ hiện khi chọn Tiền mặt)
                        if (_selectedMethod == 'CASH') ...[
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blue),
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              labelText: "Tiền khách đưa",
                              labelStyle: const TextStyle(fontSize: 16),
                              prefixIcon: const Icon(Icons.attach_money, size: 28),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              filled: true,
                              fillColor: Colors.white
                            ),
                            onChanged: (val) {
                              String cleanVal = val.replaceAll('.', '').replaceAll(',', '');
                              double valDouble = double.tryParse(cleanVal) ?? 0;
                              _updateAmountReceived(valDouble);
                            },
                          ),
                          const SizedBox(height: 15),

                          // Gợi ý tiền
                          Wrap(
                            spacing: 10, runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildQuickMoneyBtn(_finalTotal, "Vừa đủ", isSpecial: true),
                              ...smartSuggestions.map((amount) => _buildQuickMoneyBtn(amount, numberFormat.format(amount))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10, runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: hardDenominations.map((amount) => _buildQuickMoneyBtn(amount, numberFormat.format(amount))).toList(),
                          ),
                          
                          const Spacer(),

                          // 3. HIỂN THỊ TIỀN THỪA
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                            decoration: BoxDecoration(
                              color: _changeAmount >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _changeAmount >= 0 ? Colors.green.shade200 : Colors.red.shade200, width: 2)
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_changeAmount >= 0 ? "TIỀN THỪA:" : "CÒN THIẾU:", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _changeAmount >= 0 ? Colors.green[800] : Colors.red[800])
                                ),
                                Text(currencyFormat.format(_changeAmount.abs()), 
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _changeAmount >= 0 ? Colors.green[700] : Colors.red[700])
                                ),
                              ],
                            ),
                          )
                        ] else ...[
                          // Giao diện QR (Placeholder)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2, size: 150, color: Colors.grey[400]),
                                  const SizedBox(height: 20),
                                  const Text("Quét mã QR để thanh toán", style: TextStyle(fontSize: 18, color: Colors.grey)),
                                  Text(currencyFormat.format(_finalTotal), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                                ],
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // --- NÚT XÁC NHẬN ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: (_selectedMethod == 'CASH' && _changeAmount < 0) 
                  ? null 
                  : () {
                      // Tính lại discount amount để gửi về
                      double finalDiscountAmt = (_discountType == 'PERCENT') 
                          ? widget.totalAmount * (_discountValue / 100) 
                          : _discountValue;

                      widget.onConfirm(
                        _selectedMethod, 
                        _amountReceived,
                        finalDiscountAmt,
                        _discountType
                      );
                      Navigator.of(context).pop();
                    },
                child: const Text("HOÀN TẤT THANH TOÁN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGETS CON ---

  Widget _buildDiscountSection(NumberFormat currency) {
    bool isAmount = _discountType == 'AMOUNT';
    bool isPercent = _discountType == 'PERCENT';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Khuyến mãi / Giảm giá", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDiscountTab('NONE', 'Không', Icons.close),
            const SizedBox(width: 10),
            _buildDiscountTab('AMOUNT', 'Trừ tiền', Icons.money_off),
            const SizedBox(width: 10),
            _buildDiscountTab('PERCENT', 'Theo %', Icons.percent),
          ],
        ),
        
        // Hiệu ứng mở rộng khu vực chọn mệnh giá
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: (_discountType == 'NONE') ? 0 : 70,
          margin: const EdgeInsets.only(top: 10),
          curve: Curves.easeInOut,
          child: SingleChildScrollView( // Tránh overflow khi animation
            physics: const NeverScrollableScrollPhysics(),
            child: (_discountType == 'NONE') ? const SizedBox.shrink() : Row(
              children: [
                // PRESET BUTTONS
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: isAmount 
                      ? [5000, 10000, 20000, 50000].map((val) => _buildDiscountChip(val.toDouble(), false)).toList()
                      : [5, 10, 15, 20].map((val) => _buildDiscountChip(val.toDouble(), true)).toList(),
                  ),
                ),
                
                const SizedBox(width: 10),
                
                // CUSTOM INPUT
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _customDiscountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: isAmount ? "Nhập số tiền" : "Nhập %",
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixText: isAmount ? '' : '%',
                    ),
                    onChanged: (val) {
                       double v = double.tryParse(val.replaceAll(',', '')) ?? 0;
                       setState(() {
                         _discountValue = v;
                         // Clear selection visual logic if needed
                       });
                       _calculateValues();
                    },
                  ),
                )
              ],
            ),
          ),
        ),

        // Hiển thị số tiền giảm được
        if (_discountType != 'NONE')
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Đã giảm: -${currency.format(widget.totalAmount - _finalTotal)}",
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildDiscountTab(String type, String label, IconData icon) {
    bool isSelected = _discountType == type;
    return Expanded(
      child: InkWell(
        onTap: () => _setDiscount(type, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange[50] : Colors.grey[100],
            border: Border.all(color: isSelected ? Colors.orange : Colors.transparent),
            borderRadius: BorderRadius.circular(8)
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.deepOrange : Colors.grey),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.deepOrange : Colors.grey[700]))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountChip(double value, bool isPercent) {
    bool isSelected = _discountValue == value;
    String label = isPercent ? "${value.toInt()}%" : "${(value/1000).toInt()}k";
    
    return InkWell(
      onTap: () {
        _customDiscountController.clear();
        setState(() {
          _discountValue = value;
        });
        _calculateValues();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.blue[800])),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black)),
      ],
    );
  }

  Widget _buildMethodBtn(String id, String label, IconData icon) {
    final isSelected = _selectedMethod == id;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown[700] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.brown[700]! : Colors.grey.shade300, width: 2),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[700], size: 26),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMoneyBtn(double amount, String label, {bool isSpecial = false}) {
    final isSelected = _amountReceived == amount;
    Color baseColor = _getNoteColor(amount);
    if (isSpecial) baseColor = Colors.blueGrey;

    return InkWell(
      onTap: () => _updateAmountReceived(amount),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 90, height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? baseColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: baseColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: baseColor.withOpacity(0.4), blurRadius: 4)] : [],
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : baseColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Color _getNoteColor(double amount) {
    if (amount == 500000) return const Color(0xFF00ACC1);
    if (amount == 200000) return const Color(0xFFFF7043);
    if (amount == 100000) return const Color(0xFF66BB6A);
    if (amount == 50000) return const Color(0xFFEC407A);
    if (amount == 20000) return const Color(0xFF42A5F5);
    if (amount == 10000) return const Color(0xFFFFCA28);
    return Colors.blueGrey;
  }

  List<double> _getSmartSuggestions(double total) {
    List<double> suggestions = [];
    double next10 = ((total / 10000).ceil()) * 10000;
    if (next10 > total && !suggestions.contains(next10)) suggestions.add(next10);
    double next50 = ((total / 50000).ceil()) * 50000;
    if (next50 > total && !suggestions.contains(next50)) suggestions.add(next50);
    double next100 = ((total / 100000).ceil()) * 100000;
    if (next100 > total && !suggestions.contains(next100)) suggestions.add(next100);
    if (500000 > total && !suggestions.contains(500000)) suggestions.add(500000);
    return suggestions.take(3).toList();
  }
}