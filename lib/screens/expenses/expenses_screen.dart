import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  Map<String, double> _summary = {};
  List<Map<String, dynamic>> _monthly = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await DatabaseHelper.instance.getExpenseSummary();
    final monthly = await DatabaseHelper.instance.getMonthlyExpenses();
    if (mounted) {
      setState(() {
        _summary = summary;
        _monthly = monthly;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat('#,###', 'ru');

    final service = _summary['service'] ?? 0;
    final parts = _summary['parts'] ?? 0;
    final diag = _summary['diagnostics'] ?? 0;
    final total = service + parts + diag;

    return Scaffold(
      appBar: AppBar(title: const Text('Расходы')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Total card
                Card(
                  color: cs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('Всего потрачено',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: cs.onPrimaryContainer)),
                        const SizedBox(height: 8),
                        Text('${fmt.format(total.toInt())} ₽',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Breakdown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('По категориям',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 16),
                        if (total > 0) ...[
                          SizedBox(
                            height: 200,
                            child: _PieChart(
                              data: {
                                'Обслуживание': service,
                                'Запчасти': parts,
                                'Ремонт': diag,
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _ExpenseRow(Icons.build, 'Обслуживание', service, Colors.blue, fmt),
                        _ExpenseRow(Icons.settings_suggest, 'Запчасти', parts, Colors.teal, fmt),
                        _ExpenseRow(Icons.medical_services, 'Ремонт', diag, Colors.orange, fmt),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Monthly chart
                if (_monthly.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('По месяцам',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _BarChart(monthly: _monthly),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final NumberFormat fmt;

  const _ExpenseRow(this.icon, this.label, this.amount, this.color, this.fmt);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text('${fmt.format(amount.toInt())} ₽',
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final Map<String, double> data;

  const _PieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.blue, Colors.teal, Colors.orange];
    final entries = data.entries.toList();
    final total = data.values.fold(0.0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                final pct = total > 0 ? (entry.value / total * 100) : 0.0;
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: entry.value,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(entries.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(entries[i].key, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;

  const _BarChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = monthly
        .map((m) => (m['total'] as num?)?.toDouble() ?? 0.0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        barGroups: List.generate(monthly.length, (i) {
          final val = (monthly[i]['total'] as num?)?.toDouble() ?? 0.0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: cs.primary,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= monthly.length) return const SizedBox();
                final month = monthly[i]['month'] as String? ?? '';
                return Text(month.length > 7 ? month.substring(5) : month,
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
