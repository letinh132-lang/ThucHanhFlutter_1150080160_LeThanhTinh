import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/add_transaction_form.dart';
import '../widgets/transaction_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final f = NumberFormat.decimalPattern('vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chi tiêu cá nhân'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TransactionPieChart(transactions: txProvider.transactions),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: txProvider.transactions.length,
              itemBuilder: (ctx, i) {
                final tx = txProvider.transactions[i];
                final isIncome = tx.isIncome;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(tx.category.characters.first.toUpperCase()),
                  ),
                  title: Text(tx.title),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy – HH:mm').format(tx.date)} • ${tx.category}',
                  ),
                  trailing: Text(
                    (isIncome ? '+' : '-') + f.format(tx.amount),
                    style: TextStyle(
                      color: isIncome ? Colors.teal : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            showDragHandle: true,
            isScrollControlled: true,
            context: context,
            builder: (_) => const AddTransactionForm(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm giao dịch'),
      ),
    );
  }
}
