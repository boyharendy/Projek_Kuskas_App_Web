import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme.dart';
import '../models/transaction.dart' as model;
import '../utils/formatters.dart';
import '../utils/transaction_notifier.dart';
import '../widgets/transaction/export_dialog.dart';
import '../services/ai_advisor_service.dart';
import '../widgets/transaction/asisten_kuskas_card.dart';
import '../widgets/profile_avatar_button.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _period = 'Bulanan';
  bool _isAiLoading = false;
  Map<String, dynamic>? _aiAdvice;
  String? _lastAnalyzedDataHash;
  int _hoveredTrendIndex = -1;
  late Future<List<model.Transaction>> _txsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _txsFuture = _fetchTransactions();
    TransactionNotifier.notifier.addListener(_onTransactionChanged);
  }

  void _onTransactionChanged() {
    if (mounted) {
      setState(() {
        _txsFuture = _fetchTransactions();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    TransactionNotifier.notifier.removeListener(_onTransactionChanged);
    super.dispose();
  }

  Future<List<model.Transaction>> _fetchTransactions() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    final response = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('transaction_date', ascending: false);
        
    return (response as List).map((json) => model.Transaction.fromJson(json)).toList();
  }

  List<model.Transaction> _filterTransactions(List<model.Transaction> allTxs, String period) {
    final now = DateTime.now();
    return allTxs.where((t) {
      if (period == 'Mingguan') {
        return now.difference(t.transactionDate).inDays <= 7;
      } else if (period == 'Bulanan') {
        return t.transactionDate.month == now.month && t.transactionDate.year == now.year;
      } else if (period == 'Tahunan') {
        return t.transactionDate.year == now.year;
      } else if (period == 'Semua') {
        return true;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _generateBarChartData(List<model.Transaction> txs, String period) {
    if (period == 'Mingguan') {
      final Map<int, Map<String, double>> dailyData = {};
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        dailyData[date.day] = {'income': 0, 'expense': 0};
      }
      for (final t in txs) {
        if (dailyData.containsKey(t.transactionDate.day)) {
          dailyData[t.transactionDate.day]![t.type] = dailyData[t.transactionDate.day]![t.type]! + t.amount;
        }
      }
      return dailyData.entries.map((e) => {'label': e.key.toString(), 'income': e.value['income'], 'expense': e.value['expense']}).toList();
    } else if (period == 'Bulanan') {
      final weekData = {
        1: {'income': 0.0, 'expense': 0.0},
        2: {'income': 0.0, 'expense': 0.0},
        3: {'income': 0.0, 'expense': 0.0},
        4: {'income': 0.0, 'expense': 0.0},
      };
      for(final t in txs) {
        int week = ((t.transactionDate.day - 1) / 7).floor() + 1;
        if(week > 4) week = 4;
        weekData[week]![t.type] = weekData[week]![t.type]! + t.amount;
      }
      return weekData.entries.map((e) => {'label': 'W${e.key}', 'income': e.value['income'], 'expense': e.value['expense']}).toList();
    } else if (period == 'Tahunan') {
      final monthData = <int, Map<String, double>>{};
      for (int i=1; i<=12; i++) {
        monthData[i] = {'income': 0.0, 'expense': 0.0};
      }
      for(final t in txs) {
        monthData[t.transactionDate.month]![t.type] = monthData[t.transactionDate.month]![t.type]! + t.amount;
      }
      final monthLabels = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
      return monthData.entries.map((e) => {'label': monthLabels[e.key-1], 'income': e.value['income'], 'expense': e.value['expense']}).toList();
    } else { // Semua
      if (txs.isEmpty) return [];
      final years = txs.map((t) => t.transactionDate.year).toSet().toList()..sort();
      final Map<int, Map<String, double>> yearlyData = {};
      for (final y in years) {
        yearlyData[y] = {'income': 0.0, 'expense': 0.0};
      }
      for (final t in txs) {
        final y = t.transactionDate.year;
        yearlyData[y]![t.type] = yearlyData[y]![t.type]! + t.amount;
      }
      return yearlyData.entries.map((e) => {
        'label': e.key.toString(),
        'income': e.value['income'],
        'expense': e.value['expense'],
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16.0,
        title: const Row(
          children: [
            ProfileAvatarButton(),
            SizedBox(width: 12),
            Text(
              'Statistik',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primaryLight,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Pemasukan'),
          ],
        ),
      ),
      body: FutureBuilder<List<model.Transaction>>(
        future: _txsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final allTransactions = snapshot.data ?? [];
          final filteredTxs = _filterTransactions(allTransactions, _period);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(filteredTxs, allTransactions),
              _buildCategoryTab(filteredTxs, 'expense'),
              _buildCategoryTab(filteredTxs, 'income'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(List<model.Transaction> txs, List<model.Transaction> allTxs) {
    final barData = _generateBarChartData(txs, _period);

    final totalIncome = txs
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = txs
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final hashKey = '${_period}_${txs.length}_${totalIncome}_${totalExpense}';
    
    if (_lastAnalyzedDataHash != hashKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateAiAdvice(txs);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: 120, // Spacing for floating navigation bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExportButtons(txs),
          const SizedBox(height: AppSpacing.xl),

          AsistenKuskasCard(
            isLoading: _isAiLoading || _aiAdvice == null,
            status: _aiAdvice?['status'] ?? 'Menghitung...',
            statusColor: _aiAdvice?['statusColor'] ?? 'blue',
            commentary: _aiAdvice?['commentary'] ?? 'Sedang menganalisis kondisi keuangan Anda...',
            tips: List<String>.from(_aiAdvice?['tips'] ?? []),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            'Pemasukan vs Pengeluaran',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          _buildBarChart(barData),
          const SizedBox(height: AppSpacing.xxl),

          _buildTrendBalanceCard(txs, allTxs),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(List<model.Transaction> txs, String type) {
    final isExpense = type == 'expense';
    final transactions = txs.where((t) => isExpense ? t.isExpense : t.isIncome).toList();
    
    final categoryTotals = <String, double>{};
    final categoryIcons = <String, IconData>{};
    for (final t in transactions) {
      categoryTotals[t.categoryName] = (categoryTotals[t.categoryName] ?? 0) + t.amount;
      categoryIcons[t.categoryName] = t.categoryIcon;
    }
    
    final total = categoryTotals.values.fold<double>(0, (s, v) => s + v);
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      AppColors.primary,
      AppColors.accent,
      Colors.lightBlue,
      Colors.pinkAccent,
      AppColors.secondary,
      Colors.amber,
      Colors.teal,
      Colors.deepOrange,
    ];

    if (transactions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _buildPeriodSelector(),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Belum ada data untuk periode ini.',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: 120, // Spacing for floating navigation bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: AppSpacing.xl),

          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            isExpense ? 'Total Pengeluaran' : 'Total Pemasukan',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          _buildDonutChart(sorted, colors, total),
          const SizedBox(height: AppSpacing.xxl),

          ...sorted.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final percent = total > 0 ? (e.value / total * 100) : 0;
            return _buildCategoryRow(
              categoryIcons[e.key] ?? Icons.more_horiz_rounded,
              e.key,
              e.value,
              percent.toDouble(),
              colors[i % colors.length],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: ['Mingguan', 'Bulanan', 'Tahunan'].map((p) {
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
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox();
    
    double maxVal = 0.0;
    for (var d in data) {
      if (d['income'] > maxVal) maxVal = d['income'] as double;
      if (d['expense'] > maxVal) maxVal = d['expense'] as double;
    }
    if (maxVal == 0) maxVal = 1.0; 

    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 24, right: 16, bottom: 8, left: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.1,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => const Color(0xFF0E132D).withOpacity(0.9),
              tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final String typeLabel = rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                return BarTooltipItem(
                  '$typeLabel\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: CurrencyFormatter.format(rod.toY),
                      style: TextStyle(
                        color: rodIndex == 0 ? AppColors.income : AppColors.expense,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1.0,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value % 1 != 0) return const SizedBox.shrink();
                  final int index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data[index]['label'],
                      style: const TextStyle(color: AppColors.textHint, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: maxVal / 4,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Text(
                      CurrencyFormatter.formatCompactNoSymbol(value),
                      style: const TextStyle(color: AppColors.textHint, fontSize: 8),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border.withOpacity(0.5),
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            final index = e.key;
            final item = e.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item['income'] as double,
                  color: AppColors.income,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: item['expense'] as double,
                  color: AppColors.expense,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildTrendBalanceCard(List<model.Transaction> filteredTxs, List<model.Transaction> allTxs) {
    final allTimeBalance = allTxs.fold<double>(0.0, (sum, t) {
      return sum + (t.isIncome ? t.amount : -t.amount);
    });

    final periodIncome = filteredTxs
        .where((t) => t.isIncome)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final periodExpense = filteredTxs
        .where((t) => t.isExpense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final periodSavings = periodIncome - periodExpense;

    final Map<String, double> categorySums = {};
    for (final t in filteredTxs.where((t) => t.isExpense)) {
      categorySums[t.categoryName] = (categorySums[t.categoryName] ?? 0.0) + t.amount;
    }
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<_TrendSegment> segments = [];
    final colors = [
      AppColors.primary,       // Indigo
      AppColors.secondary,     // Cyan
      AppColors.accent,        // Fuchsia
      AppColors.income,        // Emerald Green
      Colors.amber,            // Amber
    ];

    if (periodIncome > 0 && periodSavings > 0) {
      segments.add(_TrendSegment(
        label: 'Tabungan',
        amount: periodSavings,
        color: colors[0],
        isIncome: true,
      ));
    }

    int colorIdx = segments.length;
    double otherExpenseTotal = 0.0;
    final maxExpenseSegments = (periodIncome > 0 && periodSavings > 0) ? 3 : 4;
    for (int i = 0; i < sortedCategories.length; i++) {
      final cat = sortedCategories[i];
      if (i < maxExpenseSegments) {
        segments.add(_TrendSegment(
          label: cat.key,
          amount: cat.value,
          color: colors[colorIdx % colors.length],
          isIncome: false,
        ));
        colorIdx++;
      } else {
        otherExpenseTotal += cat.value;
      }
    }

    if (otherExpenseTotal > 0) {
      segments.add(_TrendSegment(
        label: 'Pengeluaran Lainnya',
        amount: otherExpenseTotal,
        color: colors[colorIdx % colors.length],
        isIncome: false,
      ));
    }

    final List<PieChartSectionData> sections = [];
    if (segments.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.white.withOpacity(0.08),
          value: 1,
          title: '',
          radius: 26,
        ),
      );
    } else {
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        final isHovered = i == _hoveredTrendIndex;
        sections.add(
          PieChartSectionData(
            color: seg.color,
            value: seg.amount,
            title: '',
            radius: isHovered ? 32.0 : 26.0,
          ),
        );
      }
    }

    final String centerAmountText;
    final String centerLabelText;
    if (_hoveredTrendIndex != -1 && _hoveredTrendIndex < segments.length) {
      final hoveredSeg = segments[_hoveredTrendIndex];
      centerAmountText = CurrencyFormatter.formatNoSymbol(hoveredSeg.amount);
      centerLabelText = hoveredSeg.isIncome ? 'Pemasukan' : 'Pengeluaran';
    } else {
      centerAmountText = CurrencyFormatter.formatNoSymbol(periodSavings.abs());
      centerLabelText = periodSavings >= 0 ? 'Tabungan Anda' : 'Defisit Anda';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0x1F0F1532), // Translucent dark navy
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.03),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Saat Ini',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatNoSymbol(allTimeBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: AppColors.surfaceVariant,
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: _period,
                      onSelected: (String val) {
                        setState(() {
                          _period = val;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      offset: const Offset(0, 44),
                      itemBuilder: (BuildContext context) {
                        return ['Mingguan', 'Bulanan', 'Tahunan'].map((p) {
                          return PopupMenuItem<String>(
                            value: p,
                            child: Text(
                              p,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _period == 'Mingguan'
                                  ? 'Week'
                                  : _period == 'Bulanan'
                                      ? 'Month'
                                      : 'Year',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            centerAmountText,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            centerLabelText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _hoveredTrendIndex = -1;
                                return;
                              }
                              _hoveredTrendIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sectionsSpace: 4,
                        centerSpaceRadius: 75,
                        startDegreeOffset: -90,
                        sections: sections,
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDonutChart(
    List<MapEntry<String, double>> data,
    List<Color> colors,
    double total,
  ) {
    if (total == 0 || data.isEmpty) return const SizedBox();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCompact(total),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: data.asMap().entries.map((e) {
                final i = e.key;
                final val = e.value.value;
                final radius = 24.0;
                
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: val,
                  title: '',
                  radius: radius,
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    IconData icon,
    String name,
    double amount,
    double percent,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Icon(icon, size: 18, color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: AppColors.surfaceVariant,
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons(List<model.Transaction> txs) {
    return Row(
      children: [
        // Export PDF button (Styled glass fuchsia gradient)
        Expanded(
          child: GestureDetector(
            onTap: () => _exportToPdf(txs),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'PDF Laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Export Excel button (Styled glassy green outline)
        Expanded(
          child: GestureDetector(
            onTap: () => _exportToExcel(txs),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.income.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.income.withOpacity(0.25),
                  width: 1.2,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_on_rounded, color: AppColors.income, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Excel Sheet',
                    style: TextStyle(
                      color: AppColors.income,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _exportToPdf(List<model.Transaction> txs) {
    ExportDialog.show(context, format: 'pdf');
  }

  void _exportToExcel(List<model.Transaction> txs) {
    ExportDialog.show(context, format: 'excel');
  }

  void _updateAiAdvice(List<model.Transaction> txs) {
    final totalIncome = txs
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = txs
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    
    final hashKey = '${_period}_${txs.length}_${totalIncome}_${totalExpense}';
    if (_lastAnalyzedDataHash == hashKey && _aiAdvice != null && !_isAiLoading) {
      return;
    }
    
    _lastAnalyzedDataHash = hashKey;
    
    // Gunakan post-frame state change untuk memicu loading UI
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isAiLoading = true;
        });
      }
    });
    
    AIAdvisorService.getFinancialAdvice(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      transactions: txs,
      period: _period,
    ).then((advice) {
      if (mounted && _lastAnalyzedDataHash == hashKey) {
        setState(() {
          _aiAdvice = advice;
          _isAiLoading = false;
        });
      }
    }).catchError((error) {
      debugPrint('Error updating AI advice: $error');
      if (mounted && _lastAnalyzedDataHash == hashKey) {
        setState(() {
          _isAiLoading = false;
        });
      }
    });
  }
}

class _TrendSegment {
  final String label;
  final double amount;
  final Color color;
  final bool isIncome;

  _TrendSegment({
    required this.label,
    required this.amount,
    required this.color,
    required this.isIncome,
  });
}
