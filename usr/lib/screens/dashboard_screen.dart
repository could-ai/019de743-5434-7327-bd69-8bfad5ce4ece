import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../integrations/supabase.dart';
import 'dart:html' as html;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _webhookController = TextEditingController();
  bool _isLoading = true;
  String? _signatureUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final supabase = SupabaseConfig.client;
      final settings = await supabase.from('settings').select().eq('id', 1).maybeSingle();
      if (settings != null) {
        if (mounted) {
          setState(() {
            _webhookController.text = settings['webhook_url'] ?? '';
            _signatureUrl = settings['signature_url'];
          });
        }
      } else {
        await supabase.from('settings').insert({'id': 1, 'webhook_url': ''});
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWebhook() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final supabase = SupabaseConfig.client;
      await supabase.from('settings').update({'webhook_url': _webhookController.text}).eq('id', 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Webhook saved successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving webhook: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _uploadSignature() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isSaving = true;
        });
        
        final fileBytes = result.files.first.bytes;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}';
        
        if (fileBytes != null) {
          final supabase = SupabaseConfig.client;
          await supabase.storage.from('signatures').uploadBinary(fileName, fileBytes);
          
          await supabase.from('settings').update({'signature_url': fileName}).eq('id', 1);
          
          setState(() {
            _signatureUrl = fileName;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature uploaded successfully.')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading signature: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _copyFormLink() {
    final currentUrl = html.window.location.href;
    final baseUrl = currentUrl.split('#')[0];
    final formLink = '$baseUrl#/form';
    Clipboard.setData(ClipboardData(text: formLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form link copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard & Settings'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Form Link',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Share this link with your customers to let them fill out invoices.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _copyFormLink,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Form Link'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Sheets Webhook URL',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Set the Apps Script Webhook URL to receive data in Google Sheets.'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _webhookController,
                        decoration: const InputDecoration(
                          labelText: 'Webhook URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveWebhook,
                        child: const Text('Save Webhook'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'E-Signature',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Upload your signature image to be included in generated PDFs.'),
                      const SizedBox(height: 16),
                      if (_signatureUrl != null && _signatureUrl!.isNotEmpty) ...[
                        const Text('Current Signature:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.network(
                            SupabaseConfig.client.storage.from('signatures').getPublicUrl(_signatureUrl!),
                            errorBuilder: (context, error, stackTrace) => const Text('Could not load image.'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _uploadSignature,
                        icon: const Icon(Icons.upload),
                        label: Text(_signatureUrl == null ? 'Upload Signature' : 'Replace Signature'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
