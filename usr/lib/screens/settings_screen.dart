import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../integrations/supabase.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _webhookCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _signatureUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await SupabaseConfig.client
          .from('settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      
      if (data != null && mounted) {
        setState(() {
          _webhookCtrl.text = data['google_sheets_webhook_url'] ?? '';
          _signatureUrl = data['signature_url'];
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWebhook() async {
    setState(() { _isSaving = true; });
    try {
      await SupabaseConfig.client.from('settings').upsert({
        'id': 1,
        'google_sheets_webhook_url': _webhookCtrl.text,
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  Future<void> _uploadSignature() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes == null) return;

      setState(() { _isSaving = true; });

      try {
        final ext = file.name.split('.').last;
        final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.$ext';
        
        await SupabaseConfig.client.storage
            .from('signatures')
            .uploadBinary(fileName, file.bytes!);

        final String path = SupabaseConfig.client.storage.from('signatures').getPublicUrl(fileName);

        await SupabaseConfig.client.from('settings').upsert({
          'id': 1,
          'signature_url': path,
          'updated_at': DateTime.now().toIso8601String(),
        });

        setState(() {
          _signatureUrl = path;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature uploaded successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      } finally {
        if (mounted) {
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Google Sheets Webhook URL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Provide an Apps Script Webhook URL to automatically sync new invoices.'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _webhookCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Webhook URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveWebhook,
                        child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator()) : const Text('Save Webhook'),
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
                      const Text('E-Signature', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Upload a signature image to automatically attach it to generated PDFs.'),
                      const SizedBox(height: 16),
                      if (_signatureUrl != null && _signatureUrl!.isNotEmpty) ...[
                        const Text('Current Signature:'),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                          child: Image.network(_signatureUrl!),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _uploadSignature,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload New Signature'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
