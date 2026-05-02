import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../services/pdf_service.dart';
import '../integrations/supabase.dart';

class SuccessScreen extends StatefulWidget {
  final String? invoiceId;

  const SuccessScreen({super.key, required this.invoiceId});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  Future<Uint8List>? _pdfFuture;
  String _customerName = 'Customer';
  String _dateStr = '';

  @override
  void initState() {
    super.initState();
    if (widget.invoiceId != null) {
      _pdfFuture = PdfService.generateInvoicePdf(widget.invoiceId!);
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    try {
      final invoice = await SupabaseConfig.client
          .from('invoices')
          .select('customer_name, created_at')
          .eq('id', widget.invoiceId as Object)
          .single();
      setState(() {
        _customerName = invoice['customer_name'] ?? 'Customer';
        final date = DateTime.parse(invoice['created_at']);
        _dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      });
      
      // Auto-trigger the Google Sheets sync via edge function
      try {
        await SupabaseConfig.client.functions.invoke(
          'sync_to_sheets',
          body: {'record': {'id': widget.invoiceId}},
        );
      } catch (e) {
        print('Error triggering sheet sync: $e');
      }

    } catch (e) {
      print('Error fetching details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.invoiceId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Invalid Invoice ID')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Generated'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _pdfFuture == null
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (format) => _pdfFuture!,
              canChangeOrientation: false,
              canChangePageFormat: false,
              pdfFileName: 'Proforma_${_customerName.replaceAll(' ', '_')}_$_dateStr.pdf',
            ),
    );
  }
}
