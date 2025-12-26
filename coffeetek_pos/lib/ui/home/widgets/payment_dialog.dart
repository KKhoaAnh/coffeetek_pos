import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(String paymentMethod, double amountReceived) onConfirm;

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
  double _amountReceived = 0;
  double _changeAmount = 0;

  @override
  void initState() {
    super.initState();
    _amountReceived = widget.totalAmount;
    _amountController.text = NumberFormat('#,###', 'vi_VN').format(_amountReceived);
  }

  void _updateAmount(double amount) {
    setState(() {
      _amountReceived = amount;
      _changeAmount = _amountReceived - widget.totalAmount;
      _amountController.text = NumberFormat('#,###', 'vi_VN').format(_amountReceived);
    });
  }

  Color _getNoteColor(double amount) {
    if (amount == 500000) return const Color(0xFF00ACC1); // Xanh lơ (500k)
    if (amount == 200000) return const Color(0xFFFF7043); // Đỏ cam (200k)
    if (amount == 100000) return const Color(0xFF66BB6A); // Xanh lá (100k)
    if (amount == 50000) return const Color(0xFFEC407A);  // Hồng tím (50k)
    if (amount == 20000) return const Color(0xFF42A5F5);  // Xanh dương (20k)
    if (amount == 10000) return const Color(0xFFFFCA28);  // Vàng nâu (10k)
    
    return Colors.blueGrey;
  }

  List<double> _getSmartSuggestions() {
    List<double> suggestions = [];
    double total = widget.totalAmount;
    
    double next10 = ((total / 10000).ceil()) * 10000;
    if (next10 > total && !suggestions.contains(next10)) suggestions.add(next10);

    double next50 = ((total / 50000).ceil()) * 50000;
    if (next50 > total && !suggestions.contains(next50)) suggestions.add(next50);

    double next100 = ((total / 100000).ceil()) * 100000;
    if (next100 > total && !suggestions.contains(next100)) suggestions.add(next100);
    
    if (500000 > total && !suggestions.contains(500000)) suggestions.add(500000);

    return suggestions.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    final smartSuggestions = _getSmartSuggestions();
    
    final hardDenominations = [500000.0, 200000.0, 100000.0, 50000.0];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("THANH TOÁN", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Tổng phải thu", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        currencyFormat.format(widget.totalAmount),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 30),

            Row(
              children: [
                Expanded(child: _buildMethodBtn('CASH', 'TIỀN MẶT', Icons.money)),
                const SizedBox(width: 15),
                Expanded(child: _buildMethodBtn('TRANSFER', 'CHUYỂN KHOẢN', Icons.qr_code)),
              ],
            ),
            const SizedBox(height: 25),

            if (_selectedMethod == 'CASH') ...[
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: "Tiền khách đưa",
                  labelStyle: const TextStyle(fontSize: 18),
                  prefixIcon: const Icon(Icons.attach_money, size: 30),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onChanged: (val) {
                  String cleanVal = val.replaceAll('.', '').replaceAll(',', '');
                  setState(() {
                    _amountReceived = double.tryParse(cleanVal) ?? 0;
                    _changeAmount = _amountReceived - widget.totalAmount;
                  });
                },
              ),
              const SizedBox(height: 15),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                children: [
                  _buildQuickMoneyBtn(widget.totalAmount, "Vừa đủ", isSpecial: true),
                  ...smartSuggestions.map(
                    (amount) => _buildQuickMoneyBtn(amount, numberFormat.format(amount))
                  ),
                ],
              ),
              
              const SizedBox(height: 10),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,  
                runSpacing: 10,
                children: hardDenominations.map((amount) => 
                   _buildQuickMoneyBtn(amount, numberFormat.format(amount))
                ).toList(),
              ),

              const SizedBox(height: 25),
              
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: _changeAmount >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _changeAmount >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                    width: 2
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _changeAmount >= 0 ? "TIỀN THỪA:" : "CÒN THIẾU:", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        color: _changeAmount >= 0 ? Colors.green[800] : Colors.red[800]
                      )
                    ),
                    Text(
                      currencyFormat.format(_changeAmount.abs()), 
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900, 
                        color: _changeAmount >= 0 ? Colors.green[700] : Colors.red[700]
                      )
                    ),
                  ],
                ),
              )
            ],

            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: (_selectedMethod == 'CASH' && _changeAmount < 0) 
                  ? null 
                  : () {
                      widget.onConfirm(_selectedMethod, _amountReceived);
                      Navigator.of(context).pop();
                    },
                child: const Text("XÁC NHẬN & IN HÓA ĐƠN", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
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
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[700], size: 28),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMoneyBtn(double amount, String label, {bool isSpecial = false}) {
    final isSelected = _amountReceived == amount;
    
    final baseColor = isSpecial ? Colors.blueGrey : _getNoteColor(amount);
    
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: () => _updateAmount(amount),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? baseColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: baseColor, 
              width: isSelected ? 3 : 1.5
            ),
            boxShadow: isSelected 
                ? [BoxShadow(color: baseColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] 
                : [],
          ),
          child: Text(
            label, 
            style: TextStyle(
              color: isSelected ? Colors.white : baseColor,
              fontWeight: FontWeight.bold,
              fontSize: 18
            )
          ),
        ),
      ),
    );
  }
}