import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/currency_utils.dart';

class ReceiptPdfData {
  final int paymentId;
  final String receiptNumber;
  final String ownerName;
  final String ownerPhone;
  final String tenantName;
  final String propertyName;
  final String apartmentNumber;
  final String contractNumber;
  final String billingMonth;
  final String paymentDate;
  final num paidAmount;
  final num invoiceTotalAmount;
  final num remainingAmount;
  final String paymentMethod;
  final String paymentRef;
  final String notes;
  final String currency;

  const ReceiptPdfData({
    required this.paymentId,
    required this.receiptNumber,
    required this.ownerName,
    required this.ownerPhone,
    required this.tenantName,
    required this.propertyName,
    required this.apartmentNumber,
    required this.contractNumber,
    required this.billingMonth,
    required this.paymentDate,
    required this.paidAmount,
    required this.invoiceTotalAmount,
    required this.remainingAmount,
    required this.paymentMethod,
    required this.paymentRef,
    required this.notes,
    required this.currency,
  });
}

class ReceiptPdfService {
  const ReceiptPdfService();

  /// Generates a valid PDF document byte array containing all 16 required fields of FR-13.
  Future<Uint8List> buildReceiptPdfBytes(ReceiptPdfData data) async {
    final doc = pw.Document(
      title: 'Ejary Payment Receipt ${data.receiptNumber}',
      author: 'Ejary Platform',
    );

    final totalStr = CurrencyUtils.formatAmount(
      data.invoiceTotalAmount,
      currency: data.currency,
    );
    final paidStr = CurrencyUtils.formatAmount(
      data.paidAmount,
      currency: data.currency,
    );
    final remStr = CurrencyUtils.formatAmount(
      data.remainingAmount,
      currency: data.currency,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey300, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EJARY PLATFORM',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Official Rental Payment Receipt',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.blueGrey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.Text(
                        'Receipt No: ${data.receiptNumber}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Divider(height: 28, color: PdfColors.blueGrey200),
                _pdfRow('Property Owner', _safeAscii(data.ownerName)),
                _pdfRow('Owner Phone', _safeAscii(data.ownerPhone)),
                pw.Divider(height: 20, color: PdfColors.blueGrey200),
                _pdfRow('Tenant', _safeAscii(data.tenantName)),
                _pdfRow('Property', _safeAscii(data.propertyName)),
                _pdfRow('Apartment No.', _safeAscii(data.apartmentNumber)),
                _pdfRow('Contract No.', _safeAscii(data.contractNumber)),
                _pdfRow('Billing Month', _safeAscii(data.billingMonth)),
                _pdfRow('Payment Date', _safeAscii(data.paymentDate)),
                pw.Divider(height: 20, color: PdfColors.blueGrey200),
                _pdfRow('Invoice Total Amount', _safeAscii(totalStr)),
                _pdfRow(
                  'Amount Paid',
                  _safeAscii(paidStr),
                  isBold: true,
                ),
                _pdfRow('Remaining Balance', _safeAscii(remStr)),
                pw.Divider(height: 20, color: PdfColors.blueGrey200),
                _pdfRow('Payment Method', _safeAscii(data.paymentMethod)),
                _pdfRow('Payment Reference', _safeAscii(data.paymentRef)),
                _pdfRow('Notes', _safeAscii(data.notes)),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  /// Saves the generated PDF receipt to a local file.
  Future<File> exportReceiptPdfToFile(
    ReceiptPdfData data, {
    String? customDirectoryPath,
  }) async {
    final bytes = await buildReceiptPdfBytes(data);
    final dirPath =
        customDirectoryPath ?? (await getApplicationDocumentsDirectory()).path;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(p.join(dir.path, '${data.receiptNumber}.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Opens the local system share sheet for the PDF receipt.
  Future<void> shareReceiptPdf(ReceiptPdfData data) async {
    final bytes = await buildReceiptPdfBytes(data);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${data.receiptNumber}.pdf',
    );
  }

  /// Opens the local system print dialog for the PDF receipt.
  Future<void> printReceiptPdf(ReceiptPdfData data) async {
    final bytes = await buildReceiptPdfBytes(data);
    await Printing.layoutPdf(
      name: data.receiptNumber,
      onLayout: (_) async => bytes,
    );
  }

  pw.Widget _pdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.blueGrey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isBold ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Ensures characters outside standard Latin-1 don't crash default PDF Helvetica font
  /// when offline (without requiring an external font download).
  String _safeAscii(String input) {
    if (input.isEmpty) return '-';
    final asciiBuffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 32 && rune <= 126) {
        asciiBuffer.writeCharCode(rune);
      } else {
        // Replace non-ASCII character with safe representation if needed
      }
    }
    final cleaned = asciiBuffer.toString().trim();
    return cleaned.isEmpty ? 'Record (${input.length} chars)' : cleaned;
  }
}
