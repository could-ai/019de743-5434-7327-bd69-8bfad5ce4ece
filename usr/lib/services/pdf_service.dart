import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../integrations/supabase.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf(String invoiceId) async {
    // Fetch invoice data
    final invoice = await SupabaseConfig.client
        .from('invoices')
        .select('*')
        .eq('id', invoiceId)
        .single();

    // Fetch settings for signature
    final settings = await SupabaseConfig.client
        .from('settings')
        .select('signature_url')
        .eq('id', 1)
        .maybeSingle();

    pw.MemoryImage? signatureImage;
    if (settings != null && settings['signature_url'] != null) {
      try {
        final String sigUrl = settings['signature_url'];
        final response = await SupabaseConfig.client.storage.from('signatures').download(sigUrl.split('/').last);
        signatureImage = pw.MemoryImage(response);
      } catch (e) {
        // Ignore if signature fails to load
        print('Could not load signature: $e');
      }
    }

    final pdf = pw.Document();
    
    // Auto-generated invoice number (using part of the UUID)
    final invoiceNumber = 'INV-${invoiceId.substring(0, 8).toUpperCase()}';
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(invoice['created_at']));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PROFORMA INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #: $invoiceNumber'),
                      pw.Text('Date: $dateStr'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Customer Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text(invoice['customer_name']),
                        pw.Text(invoice['company_name']),
                        pw.Text(invoice['address']),
                        pw.Text(invoice['contact_number']),
                        pw.Text(invoice['email']),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Products Table
              pw.TableHelper.fromTextArray(
                headers: ['Description', 'Quantity', 'Unit Price', 'Total'],
                data: [
                  [
                    invoice['product_details'],
                    invoice['quantity'].toString(),
                    '\$${invoice['price'].toStringAsFixed(2)}',
                    '\$${(invoice['quantity'] * invoice['price']).toStringAsFixed(2)}',
                  ]
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 20),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Grand Total: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${invoice['total_amount'].toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 40),

              // Terms
              pw.Text('Terms & Conditions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Payment Terms: ${invoice['payment_terms']}'),
              pw.Text('Delivery Terms: ${invoice['delivery_terms']}'),

              pw.Spacer(),

              // Signature
              if (signatureImage != null) ...[
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(signatureImage, width: 120, height: 60),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Signatory'),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
