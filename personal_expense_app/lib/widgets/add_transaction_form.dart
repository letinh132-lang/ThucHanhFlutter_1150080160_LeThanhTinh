import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class AddTransactionForm extends StatefulWidget {
  const AddTransactionForm({super.key});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _amountCtl = TextEditingController();
  String _category = 'Ăn uống';
  bool _isIncome = false;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleCtl.dispose();
    _amountCtl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final tx = TransactionModel(
      title: _titleCtl.text.trim(),
      amount: double.parse(_amountCtl.text),
      date: _date,
      category: _category,
      isIncome: _isIncome,
    );
    context.read<TransactionProvider>().addTransaction(tx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Switch(
                  value: _isIncome,
                  onChanged: (v) => setState(() => _isIncome = v),
                ),
                const SizedBox(width: 8),
                Text(_isIncome ? 'Thu nhập' : 'Chi tiêu'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: _date,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  icon: const Icon(Icons.date_range),
                  label: const Text('Chọn ngày'),
                ),
              ],
            ),
            TextFormField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập mô tả' : null,
            ),
            TextFormField(
              controller: _amountCtl,
              decoration: const InputDecoration(labelText: 'Số tiền'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nhập số tiền';
                final d = double.tryParse(v);
                if (d == null || d <= 0) return 'Số tiền phải > 0';
                return null;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              items: const [
                DropdownMenuItem(value: 'Ăn uống', child: Text('Ăn uống')),
                DropdownMenuItem(value: 'Di chuyển', child: Text('Di chuyển')),
                DropdownMenuItem(value: 'Hóa đơn', child: Text('Hóa đơn')),
                DropdownMenuItem(value: 'Mua sắm', child: Text('Mua sắm')),
                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'Khác'),
              decoration: const InputDecoration(labelText: 'Danh mục'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('Lưu giao dịch'),
            ),
          ],
        ),
      ),
    );
  }
}
