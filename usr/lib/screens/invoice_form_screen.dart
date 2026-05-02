import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../integrations/supabase.dart';
import '../services/invoice_pdf_service.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _productDetailsController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _paymentTermsController = TextEditingController(text: 'Net 30');
  final _deliveryTermsController = TextEditingController(text: 'FOB');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _productDetailsController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _paymentTermsController.dispose();
    _deliveryTermsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabase = SupabaseConfig.client;
      // Data to save
      final invoiceData = {
        'customer_name': _customerNameController.text,
        'company_name': _companyNameController.text,
        'address': _addressController.text,
        'contact_number': _contactNumberController.text,
        'email': _emailController.text,
        'product_details': _productDetailsController.text,
        'quantity': int.tryParse(_quantityController.text) ?? 1,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'payment_terms': _paymentTermsController.text,
        'delivery_terms': _deliveryTermsController.text,
        'total_amount': (int.tryParse(_quantityController.text) ?? 1) * (double.tryParse(_priceController.text) ?? 0.0),
      };

      // Save to Supabase
      final insertedData = await supabase.from('invoices').insert(invoiceData).select().single();
      
      // Trigger Edge Function
      try {
        await SupabaseEdgeFunctions.invoke(
          'sync_to_sheets',
          body: {'record': insertedData},
        );
      } catch (e) {
        debugPrint('Failed to sync to sheets: $e');
      }

      // Fetch Signature
      Uint8List? signatureBytes;
      try {
        final settings = await supabase.from('settings').select('signature_url').eq('id', 1).single();
        final signatureUrl = settings['signature_url'] as String?;
        if (signatureUrl != null && signatureUrl.isNotEmpty) {
           final response = await supabase.storage.from('signatures').download(signatureUrl);
           signatureBytes = response;
        }
      } catch (e) {
        debugPrint('Failed to fetch signature: $e');
      }

      // Generate PDF
      final pdfBytes = await InvoicePdfService.generateProformaInvoice(
        data: invoiceData,
        invoiceNumber: insertedData['id'].toString().substring(0, 8).toUpperCase(),
        signatureBytes: signatureBytes,
      );

      // Download PDF
      final sanitizedName = _customerNameController.text.replaceAll(' ', '_');
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      await InvoicePdfService.downloadPdf(pdfBytes, 'Proforma_${sanitizedName}_$dateStr.pdf');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form Submitted! Generating PDF...')),
      );

    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Proforma Invoice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Customer Information', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                maxLines: 2,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _contactNumberController,
                      decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                         if (value == null || value.isEmpty) return 'Required';
                         if (!value.contains('@')) return 'Invalid email';
                         return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Product Details', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productDetailsController,
                decoration: const InputDecoration(labelText: 'Product Description', border: OutlineInputBorder()),
                maxLines: 2,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Unit Price', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Terms & Conditions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentTermsController,
                decoration: const InputDecoration(labelText: 'Payment Terms', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deliveryTermsController,
                decoration: const InputDecoration(labelText: 'Delivery Terms', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator() 
                  : const Text('Generate Invoice & Complete', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}