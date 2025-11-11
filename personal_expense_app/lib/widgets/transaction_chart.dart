import 'dart:math';
import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionPieChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  const TransactionPieChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Lọc chỉ các khoản chi tiêu (isIncome = false)
    final expenses = transactions.where((t) => !t.isIncome).toList();

    // Gom nhóm theo danh mục
    final byCategory = <String, double>{};
    double total = 0;
    for (final t in expenses) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      total += t.amount;
    }

    total = total == 0 ? 1 : total; // tránh chia 0
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      height: 250,
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Khung chứa biểu đồ
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: _PiePainter(entries: entries, total: total),
                ),
              ),
              const SizedBox(width: 16),
              // Danh sách chú thích
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final e = entries[i];
                    final pct = (e.value / total * 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _colorFor(i),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎨 Vẽ biểu đồ tròn
class _PiePainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final double total;
  _PiePainter({required this.entries, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var startAngle = -pi / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < entries.length; i++) {
      final sweep = (entries[i].value / total) * 2 * pi;
      paint.color = _colorFor(i);
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    // Viền ngoài nhẹ để dễ nhìn hơn
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.shade300;
    canvas.drawCircle(center, radius, border);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.total != total;
}

// 🎨 Màu cho từng phần
Color _colorFor(int i) {
  const colors = [
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.brown,
    Colors.blueGrey,
    Colors.purple,
    Colors.green,
  ];
  return colors[i % colors.length];
}
