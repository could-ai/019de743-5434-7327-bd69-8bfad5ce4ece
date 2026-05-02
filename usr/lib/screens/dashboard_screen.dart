import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../integrations/supabase.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    try {
      final data = await SupabaseConfig.client
          .from('invoices')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _invoices = data;
        });
      }
    } catch (e) {
      print('Error fetching invoices: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInvoices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? const Center(child: Text('No invoices yet.'))
              : ListView.builder(
                  itemCount: _invoices.length,
                  itemBuilder: (context, index) {
                    final inv = _invoices[index];
                    final date = DateTime.parse(inv['created_at']);
                    final syncStatus = inv['sync_status'] ?? 'pending';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('${inv['customer_name']} - ${inv['company_name']}'),
                        subtitle: Text('Date: ${DateFormat('yyyy-MM-dd').format(date)} | Total: \$${inv['total_amount']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              syncStatus == 'synced' ? Icons.cloud_done : Icons.cloud_off,
                              color: syncStatus == 'synced' ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                              onPressed: () => context.go('/success?invoiceId=${inv['id']}'),
                              tooltip: 'View PDF',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
