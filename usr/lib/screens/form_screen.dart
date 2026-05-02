import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../integrations/supabase.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _customerNameCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _productDetailsCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _paymentTermsCtrl = TextEditingController();
  final _deliveryTermsCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _contactNumberCtrl.dispose();
    _emailCtrl.dispose();
    _productDetailsCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _paymentTermsCtrl.dispose();
    _deliveryTermsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final quantity = int.parse(_quantityCtrl.text);
      final price = double.parse(_priceCtrl.text);
      final totalAmount = quantity * price;

      final result = await SupabaseConfig.client.from('invoices').insert({
        'customer_name': _customerNameCtrl.text,
        'company_name': _companyNameCtrl.text,
        'address': _addressCtrl.text,
        'contact_number': _contactNumberCtrl.text,
        'email': _emailCtrl.text,
        'product_details': _productDetailsCtrl.text,
        'quantity': quantity,
        'price': price,
        'payment_terms': _paymentTermsCtrl.text,
        'delivery_terms': _deliveryTermsCtrl.text,
        'total_amount': totalAmount,
      }).select('id').single();

      if (mounted) {
        context.go('/success?invoiceId=${result['id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Invoice Request'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => context.go('/dashboard'),
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Customer Details',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_customerNameCtrl, 'Customer Name'),
                      _buildTextField(_companyNameCtrl, 'Company Name'),
                      _buildTextField(_emailCtrl, 'Email Address'),
                      _buildTextField(_contactNumberCtrl, 'Contact Number'),
                      _buildTextField(_addressCtrl, 'Address', maxLines: 3),
                      
                      const Divider(height: 48),
                      
                      const Text(
                        'Product & Terms',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_productDetailsCtrl, 'Product Details', maxLines: 3),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_quantityCtrl, 'Quantity', isNumber: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_priceCtrl, 'Unit Price', isNumber: true)),
                        ],
                      ),
                      _buildTextField(_paymentTermsCtrl, 'Payment Terms'),
                      _buildTextField(_deliveryTermsCtrl, 'Delivery Terms'),
                      
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: _isSubmitting 
                            ? const CircularProgressIndicator()
                            : const Text('Complete'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
