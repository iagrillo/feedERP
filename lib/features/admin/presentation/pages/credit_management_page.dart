import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers
final customerCreditProvider = FutureProvider.autoDispose((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('outstanding_customer_credit')
      .select()
      .order('outstanding_balance', ascending: false);
  return response;
});

final creditSummaryProvider = FutureProvider.autoDispose((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('outstanding_customer_credit')
      .select();
  
  double totalCredit = 0;
  double totalLimit = 0;
  int customersWithCredit = 0;
  double overdueAmount = 0;

  for (var row in response) {
    totalCredit += (row['outstanding_balance'] as num?)?.toDouble() ?? 0;
    totalLimit += (row['credit_limit'] as num?)?.toDouble() ?? 0;
    if ((row['outstanding_balance'] as num?)?.toDouble() ?? 0 > 0) {
      customersWithCredit++;
    }
    
    // Calculate overdue (more than 30 days old)
    if (row['last_transaction_date'] != null) {
      final lastDate = DateTime.parse(row['last_transaction_date']);
      if (DateTime.now().difference(lastDate).inDays > 30) {
        overdueAmount += (row['outstanding_balance'] as num?)?.toDouble() ?? 0;
      }
    }
  }

  return {
    'totalCredit': totalCredit,
    'totalLimit': totalLimit,
    'customersWithCredit': customersWithCredit,
    'overdueAmount': overdueAmount,
  };
});

class CreditManagementPage extends ConsumerWidget {
  const CreditManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditData = ref.watch(customerCreditProvider);
    final summaryData = ref.watch(creditSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Management'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            summaryData.when(
              data: (summary) => _buildSummaryCards(summary),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: \'),
            ),
            const SizedBox(height: 24),
            
            // Customer Credit Table
            Text(
              'Customer Credit Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            creditData.when(
              data: (customers) => _buildCustomerTable(context, customers),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: \'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    return GridView.count(
      crossAxisCount: 4,
      childAspectRatio: 1.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _MetricCard(
          title: 'Total Outstanding',
          value: '₦\',
          color: Colors.red,
        ),
        _MetricCard(
          title: 'Total Credit Limit',
          value: '₦\',
          color: Colors.blue,
        ),
        _MetricCard(
          title: 'Customers with Credit',
          value: '\',
          color: Colors.orange,
        ),
        _MetricCard(
          title: 'Overdue (30+ days)',
          value: '₦\',
          color: Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _buildCustomerTable(BuildContext context, List<dynamic> customers) {
    if (customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No customers with credit yet',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Customer Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Credit Limit')),
          DataColumn(label: Text('Outstanding')),
          DataColumn(label: Text('Transactions')),
          DataColumn(label: Text('Last Transaction')),
          DataColumn(label: Text('Action')),
        ],
        rows: customers.map((customer) {
          final outstanding = (customer['outstanding_balance'] as num?)?.toDouble() ?? 0;
          final limit = (customer['credit_limit'] as num?)?.toDouble() ?? 0;
          final utilization = limit > 0 ? (outstanding / limit) * 100 : 0;

          return DataRow(
            cells: [
              DataCell(Text(customer['name'] ?? 'N/A')),
              DataCell(Text(customer['email'] ?? 'N/A')),
              DataCell(Text(customer['phone'] ?? 'N/A')),
              DataCell(Text('₦\')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: utilization > 80
                        ? Colors.red.withOpacity(0.2)
                        : utilization > 50
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '₦\ (\%)',
                    style: TextStyle(
                      color: utilization > 80
                          ? Colors.red
                          : utilization > 50
                              ? Colors.orange
                              : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(Text('\')),
              DataCell(Text(
                customer['last_transaction_date'] != null
                    ? DateTime.parse(customer['last_transaction_date'])
                        .toString()
                        .split(' ')[0]
                    : 'N/A',
              )),
              DataCell(
                ElevatedButton(
                  onPressed: () => _showEditDialog(context, customer),
                  child: const Text('Edit'),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic customer) {
    final creditLimitController = TextEditingController(
      text: (customer['credit_limit'] as num?)?.toString() ?? '0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Credit Limit - \'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: creditLimitController,
              decoration: const InputDecoration(
                labelText: 'Credit Limit (₦)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newLimit = double.tryParse(creditLimitController.text) ?? 0;
              await Supabase.instance.client
                  .from('customers')
                  .update({'credit_limit': newLimit})
                  .eq('id', customer['id']);
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Credit limit updated')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
