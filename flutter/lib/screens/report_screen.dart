import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _period = 'Bulan ini';
  int _touchedIndexExpense = -1;
  int _touchedIndexIncome = -1;

  final List<Color> _chartColors = [
    Colors.blue.shade400,
    Colors.orange.shade400,
    Colors.green.shade400,
    Colors.purple.shade400,
    Colors.red.shade400,
    Colors.teal.shade400,
    Colors.pink.shade400,
    Colors.indigo.shade400,
    Colors.amber.shade400,
    Colors.cyan.shade400,
  ];

  @override
  Widget build(BuildContext context) {
    // In a real app, filtering would happen here based on _period
    final transactions = Transaction.dummyData;
    
    // Process categories
    final expenseMap = <String, Map<String, dynamic>>{};
    final incomeMap = <String, Map<String, dynamic>>{};
    
    double totalExpense = 0;
    double totalIncome = 0;

    for (final t in transactions) {
      if (t.isExpense) {
        totalExpense += t.amount;
        expenseMap.putIfAbsent(t.categoryName, () => {'icon': t.categoryIcon, 'amount': 0.0});
        expenseMap[t.categoryName]!['amount'] += t.amount;
      } else {
        totalIncome += t.amount;
        incomeMap.putIfAbsent(t.categoryName, () => {'icon': t.categoryIcon, 'amount': 0.0});
        incomeMap[t.categoryName]!['amount'] += t.amount;
      }
    }

    // Sort maps by amount descending
    final sortedExpenseList = expenseMap.entries.toList()
      ..sort((a, b) => (b.value['amount'] as double).compareTo(a.value['amount'] as double));
    final sortedIncomeList = incomeMap.entries.toList()
      ..sort((a, b) => (b.value['amount'] as double).compareTo(a.value['amount'] as double));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Analisis'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.download_rounded, size: 22),
              onSelected: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Export $value berhasil!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                );
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'Excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart_outlined, size: 18, color: AppColors.income),
                      SizedBox(width: AppSpacing.sm),
                      Text('Export Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'PDF',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.expense),
                      SizedBox(width: AppSpacing.sm),
                      Text('Export PDF'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Pengeluaran'),
              Tab(text: 'Pemasukan'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Filter periode
            _buildPeriodSelector(),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildTabContent(
                    isExpense: true, 
                    totalAmount: totalExpense, 
                    sortedData: sortedExpenseList, 
                    touchedIndex: _touchedIndexExpense,
                    onPieTouch: (idx) => setState(() => _touchedIndexExpense = idx),
                  ),
                  _buildTabContent(
                    isExpense: false, 
                    totalAmount: totalIncome, 
                    sortedData: sortedIncomeList,
                    touchedIndex: _touchedIndexIncome,
                    onPieTouch: (idx) => setState(() => _touchedIndexIncome = idx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: ['Hari ini', 'Minggu ini', 'Bulan ini', 'Tahun ini'].map((p) {
          final selected = _period == p;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(p),
              selected: selected,
              onSelected: (_) => setState(() => _period = p),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              showCheckmark: false,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent({
    required bool isExpense, 
    required double totalAmount, 
    required List<MapEntry<String, Map<String, dynamic>>> sortedData,
    required int touchedIndex,
    required Function(int) onPieTouch,
  }) {
    if (sortedData.isEmpty) {
      return const Center(child: Text('Tidak ada data pada periode ini'));
    }

    final topCategoryName = sortedData.first.key;
    final primaryColor = isExpense ? AppColors.expense : AppColors.income;
    final verb = isExpense ? 'Pengeluaran' : 'Pemasukan';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insight Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: primaryColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '$verb terbesarmu $_period adalah untuk $topCategoryName.',
                    style: TextStyle(
                      color: primaryColor, 
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Chart
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total $verb',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text(
                        CurrencyFormatter.format(totalAmount),
                        style: TextStyle(
                          color: primaryColor, 
                          fontSize: 20, 
                          fontWeight: FontWeight.w800
                        ),
                      ),
                    ],
                  ),
                ),
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                          onPieTouch(-1);
                          return;
                        }
                        onPieTouch(pieTouchResponse.touchedSection!.touchedSectionIndex);
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 75,
                    sections: List.generate(sortedData.length, (i) {
                      final isTouched = i == touchedIndex;
                      final fontSize = isTouched ? 16.0 : 12.0;
                      final radius = isTouched ? 35.0 : 25.0;
                      final amount = sortedData[i].value['amount'] as double;
                      final percent = (amount / totalAmount) * 100;
                      final color = _chartColors[i % _chartColors.length];

                      return PieChartSectionData(
                        color: color,
                        value: percent,
                        title: '${percent.toStringAsFixed(1)}%',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Legend / Detail List
          Text(
            'Rincian $verb',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          
          ...List.generate(sortedData.length, (i) {
            final entry = sortedData[i];
            final color = _chartColors[i % _chartColors.length];
            final amount = entry.value['amount'] as double;
            final percent = (amount / totalAmount) * 100;
            final icon = entry.value['icon'] as IconData;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, size: 20, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key, 
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          '${percent.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
