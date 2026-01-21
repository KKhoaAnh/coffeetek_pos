// import 'dart:typed_data';
// import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../domain/models/order.dart';

class PrinterService {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  Future<pw.Font> _getFont() async {
    return await PdfGoogleFonts.robotoRegular();
  }

  Future<pw.Font> _getBoldFont() async {
    return await PdfGoogleFonts.robotoBold();
  }

  // --- IN HÓA ĐƠN THANH TOÁN (BILL) ---
  Future<void> printBill(Order order, {bool isProvisional = false, double? amountReceived}) async {
    final font = await _getFont();
    final fontBold = await _getBoldFont();
    
    final doc = pw.Document();

    // Tính toán số tiền cuối cùng (Hỗ trợ tương thích ngược nếu DB chưa có finalAmount)
    double finalTotal = order.finalAmount > 0 ? order.finalAmount : (order.totalAmount - order.discountAmount);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. HEADER
              pw.Center(child: pw.Text('COFFEETEK POS', style: pw.TextStyle(font: fontBold, fontSize: 20))),
              pw.Center(child: pw.Text('ĐC: 123 Đường ABC, TP.HCM', style: pw.TextStyle(font: font, fontSize: 10))),
              pw.SizedBox(height: 5),
              pw.Divider(),
              
              // 2. INFO
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Bàn: ${order.tableName ?? order.tableId}', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                pw.Text(isProvisional ? '(TẠM TÍNH)' : '(HÓA ĐƠN)', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              ]),
              pw.Text('Mã đơn: ${order.orderCode}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('Ngày: ${dateFormat.format(order.createdDate)}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // 3. ITEMS LIST (Cập nhật giao diện mới)
              ...order.items.map((item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Tên món (Dòng riêng cho rõ ràng)
                      pw.Text(item.productName, style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      
                      // Modifiers + Notes (Hiển thị chi tiết nội dung note)
                      if (item.modifiers.isNotEmpty)
                        ...item.modifiers.map((m) {
                          // [LOGIC MỚI] Ghép tên topping + ghi chú người dùng nhập (nếu có)
                          String modDisplay = m.name;
                          if (m.userInput != null && m.userInput!.trim().isNotEmpty) {
                            modDisplay += ' (${m.userInput})'; 
                          }
                          // Nếu có giá thì hiện giá
                          String priceDisplay = m.extraPrice > 0 ? ' +${currencyFormat.format(m.extraPrice)}' : '';
                          
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10),
                            child: pw.Text(
                              '- $modDisplay$priceDisplay', 
                              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)
                            ),
                          );
                        }),

                      // Thông số: Đơn giá x Số lượng ....... Tổng tiền (Cột phải)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // Bên trái: Đơn giá gốc x Số lượng
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 10, top: 2),
                            child: pw.Text(
                              '${currencyFormat.format(item.price)} x ${item.quantity}', 
                              style: pw.TextStyle(font: font, fontSize: 11)
                            ),
                          ),
                          // Bên phải: Tổng tiền của dòng này (đã bao gồm topping * qty)
                          pw.Text(
                            currencyFormat.format(item.totalLineAmount), 
                            style: pw.TextStyle(font: fontBold, fontSize: 12)
                          ),
                        ],
                      ),
                    ],
                  )
                );
              }).toList(),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // 4. SUMMARY (Tổng kết tiền & Khuyến mãi)
              _buildRow('Tổng tiền hàng:', currencyFormat.format(order.totalAmount), font, 12),
              
              // Chỉ hiện dòng giảm giá nếu có
              if (order.discountAmount > 0)
                _buildRow(
                  'Giảm giá:', 
                  '- ${currencyFormat.format(order.discountAmount)}', 
                  font, 
                  12,
                  valueColor: PdfColors.black // In đen trắng thì không cần đỏ, nhưng nếu in nhiệt có thể chỉnh
                ),
              
              pw.SizedBox(height: 5),
              // Thành tiền cuối cùng (In đậm, to)
              _buildRow(
                'THÀNH TIỀN:', 
                currencyFormat.format(finalTotal), 
                fontBold, 
                16
              ),
              
              pw.Divider(borderStyle: pw.BorderStyle.dotted),

              // 5. PAYMENT INFO (Khách đưa & Tiền thừa)
              if (!isProvisional && amountReceived != null) ...[
                _buildRow('Khách đưa:', currencyFormat.format(amountReceived), font, 12),
                _buildRow('Tiền thừa:', currencyFormat.format(amountReceived - finalTotal), font, 12),
              ],
              
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Cảm ơn quý khách!', style: pw.TextStyle(font: font, fontSize: 12, fontStyle: pw.FontStyle.italic))),
              pw.Center(child: pw.Text('Hẹn gặp lại!', style: pw.TextStyle(font: font, fontSize: 12, fontStyle: pw.FontStyle.italic))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Bill-${order.orderCode}'
    );
  }

  // --- IN PHIẾU BẾP (KITCHEN) ---
  Future<void> printKitchen(Order order, {int reprintCount = 0, String? customTitle}) async {
    final font = await _getFont();
    final fontBold = await _getBoldFont();
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text(customTitle ?? 'PHIẾU BẾP', style: pw.TextStyle(font: fontBold, fontSize: 24))),
              if (reprintCount > 0)
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 5),
                    child: pw.Text(
                      '(IN LẠI LẦN $reprintCount)', 
                      style: pw.TextStyle(font: fontBold, fontSize: 16)
                    )
                  )
                ),
              pw.Divider(),
              pw.Text('BÀN: ${order.tableName ?? order.tableId}', style: pw.TextStyle(font: fontBold, fontSize: 30)),
              pw.Text('Mã: ${order.orderCode}', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Text('Giờ: ${dateFormat.format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Divider(thickness: 2),

              ...order.items.map((item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('${item.quantity}', style: pw.TextStyle(font: fontBold, fontSize: 22)), // Số lượng to
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: pw.Text(item.productName, style: pw.TextStyle(font: fontBold, fontSize: 18)) // Tên món to
                          ),
                        ],
                      ),
                      // Hiển thị Modifier kèm Ghi chú (userInput)
                      if (item.modifiers.isNotEmpty)
                         pw.Padding(
                           padding: const pw.EdgeInsets.only(left: 30),
                           child: pw.Text(
                             item.modifiers.map((e) {
                               String name = e.name;
                               if (e.userInput != null && e.userInput!.isNotEmpty) {
                                 name += ' (${e.userInput})';
                               }
                               return name;
                             }).join(', '), 
                             style: pw.TextStyle(font: font, fontSize: 14)
                           ),
                         ),
                      // Ghi chú chung của món (nếu có)
                      if (item.note != null && item.note!.isNotEmpty)
                         pw.Padding(
                           padding: const pw.EdgeInsets.only(left: 30),
                           child: pw.Text('Ghi chú: ${item.note}', style: pw.TextStyle(font: font, fontSize: 14, fontStyle: pw.FontStyle.italic)),
                         ),
                      pw.Divider(borderStyle: pw.BorderStyle.dotted),
                    ],
                  )
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Kitchen-${order.orderCode}'
    );
  }

  pw.Widget _buildRow(String label, String value, pw.Font font, double size, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: size)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: size, color: valueColor ?? PdfColors.black)),
        ],
      ),
    );
  }
}