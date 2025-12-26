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

  Future<void> printBill(Order order, {bool isProvisional = false, double? amountReceived}) async {
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
              pw.Center(child: pw.Text('COFFEETEK POS', style: pw.TextStyle(font: fontBold, fontSize: 20))),
              pw.Center(child: pw.Text('ĐC: 123 Đường ABC, TP.HCM', style: pw.TextStyle(font: font, fontSize: 10))),
              pw.Divider(),
              
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Bàn: ${order.tableName ?? order.tableId}', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                pw.Text(isProvisional ? '(TẠM TÍNH)' : '(HÓA ĐƠN)', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              ]),
              pw.Text('Mã đơn: ${order.orderCode}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('Ngày: ${dateFormat.format(order.createdDate)}', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              ...order.items.map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.Text(item.productName, style: pw.TextStyle(font: fontBold, fontSize: 12))),
                        pw.Text('x${item.quantity}', style: pw.TextStyle(font: font, fontSize: 12)),
                        pw.SizedBox(width: 20),
                        pw.Text(currencyFormat.format(item.totalLineAmount), style: pw.TextStyle(font: font, fontSize: 12)),
                      ],
                    ),
                    if (item.modifiers.isNotEmpty)
                      ...item.modifiers.map((m) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10),
                        child: pw.Text('+ ${m.name} (${currencyFormat.format(m.extraPrice)})', 
                            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                      )),
                    pw.SizedBox(height: 5),
                  ],
                );
              }).toList(),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              _buildRow('Tổng tiền:', currencyFormat.format(order.totalAmount), fontBold, 14),
              
              if (!isProvisional && amountReceived != null) ...[
                pw.SizedBox(height: 5),
                _buildRow('Khách đưa:', currencyFormat.format(amountReceived), font, 12),
                _buildRow('Tiền thừa:', currencyFormat.format(amountReceived - order.totalAmount), font, 12),
              ],
              
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Cảm ơn quý khách!', style: pw.TextStyle(font: font, fontSize: 12, fontStyle: pw.FontStyle.italic))),
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
                      style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.black)
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
                      if (item.modifiers.isNotEmpty)
                         pw.Padding(
                           padding: const pw.EdgeInsets.only(left: 30),
                           child: pw.Text(item.modifiers.map((e) => e.name).join(', '), style: pw.TextStyle(font: font, fontSize: 14)),
                         ),
                      if (item.note.isNotEmpty)
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

  pw.Widget _buildRow(String label, String value, pw.Font font, double size) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: size)),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: size)),
      ],
    );
  }
}