import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoicePdfService {
  static Future<Uint8List> generateProformaInvoice({
    required Map<String, dynamic> data,
    required String invoiceNumber,
    Uint8List? signatureBytes,
  }) async {
    final pdf = pw.Document();

    // Try to load a generic logo or icon if needed
    // For now we'll just use text for the logo

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoiceNumber),
              pw.SizedBox(height: 30),
              _buildCustomerInfo(data),
              pw.SizedBox(height: 30),
              _buildProductTable(data),
              pw.SizedBox(height: 20),
              _buildTotals(data),
              pw.Spacer(),
              _buildFooterAndSignature(data, signatureBytes),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String invoiceNumber) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PROFORMA INVOICE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}'),
            pw.Text('Invoice #: $invoiceNumber'),
          ],
        ),
        // Placeholder for Company Logo
        pw.Container(
          height: 60,
          width: 60,
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Center(
            child: pw.Text('YOUR\nLOGO', textAlign: pw.TextAlign.center),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerInfo(Map<String, dynamic> data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Text(data['customer_name'] ?? ''),
            pw.Text(data['company_name'] ?? ''),
            pw.Text(data['address'] ?? ''),
            pw.Text(data['contact_number'] ?? ''),
            pw.Text(data['email'] ?? ''),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('From:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Text('Your Company Name'),
            pw.Text('123 Business Street'),
            pw.Text('City, Country'),
            pw.Text('contact@yourcompany.com'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildProductTable(Map<String, dynamic> data) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final quantity = data['quantity'] as int;
    final price = data['price'] as double;
    final total = quantity * price;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Unit Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(data['product_details'] ?? '')),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(quantity.toString(), textAlign: pw.TextAlign.center)),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(price), textAlign: pw.TextAlign.right)),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormat.format(total), textAlign: pw.TextAlign.right)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotals(Map<String, dynamic> data) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final total = (data['quantity'] as int) * (data['price'] as double);

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('Total Amount: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.Text(currencyFormat.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColors.blue900)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterAndSignature(Map<String, dynamic> data, Uint8List? signatureBytes) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Payment: ${data['payment_terms']}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Delivery: ${data['delivery_terms']}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.Container(
          width: 200,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (signatureBytes != null)
                pw.Image(pw.MemoryImage(signatureBytes), height: 60)
              else
                pw.SizedBox(height: 60),
              pw.Divider(),
              pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> downloadPdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}