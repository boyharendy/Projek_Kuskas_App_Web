import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../utils/transaction_notifier.dart';
import '../widgets/transaction/transaction_item.dart';
import '../widgets/transaction/transaction_detail_sheet.dart';
import '../widgets/profile_avatar_button.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'Semua';
  final _searchController = TextEditingController();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Transaction>> _fetchTransactions() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    
    final response = await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('transaction_date', startOfMonth.toIso8601String())
        .lt('transaction_date', endOfMonth.toIso8601String())
        .order('transaction_date', ascending: false);
        
    return (response as List).map((json) => Transaction.fromJson(json)).toList();
  }

  void _showMonthYearPicker() {
    int tempYear = _selectedMonth.year;
    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                        onPressed: () => setModalState(() => tempYear--),
                      ),
                      Text(
                        tempYear.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                        onPressed: () => setModalState(() => tempYear++),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Month Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 2,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedMonth.month == index + 1 && _selectedMonth.year == tempYear;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMonth = DateTime(tempYear, index + 1);
                          });
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            monthNames[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        );
      },
    );
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
              'Riwayat Transaksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, size: 22, color: Colors.white),
            onPressed: () => _showSortSheet(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: TransactionNotifier.notifier,
        builder: (context, _, __) {
          return FutureBuilder<List<Transaction>>(
            future: _fetchTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final allTransactions = snapshot.data ?? [];
              
              // Apply local search and category/type filter
              final query = _searchController.text.toLowerCase().trim();
              final transactions = allTransactions.where((t) {
                // 1. Search Query Filter
                if (query.isNotEmpty) {
                  final matchCategory = t.categoryName.toLowerCase().contains(query);
                  final matchDesc = t.description.toLowerCase().contains(query);
                  if (!matchCategory && !matchDesc) return false;
                }
                // 2. Chip Filter (Pemasukan/Pengeluaran/Semua)
                if (_selectedFilter == 'Semua') return true;
                if (_selectedFilter == 'Pemasukan' && t.isIncome) return true;
                if (_selectedFilter == 'Pengeluaran' && t.isExpense) return true;
                return false;
              }).toList();

              // Group by date
              final grouped = <String, List<Transaction>>{};
              for (final t in transactions) {
                final key = DateFormatter.formatDay(t.transactionDate);
                grouped.putIfAbsent(key, () => []).add(t);
              }

              return Column(
                children: [
                  // Month selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary),
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                            });
                          },
                        ),
                        InkWell(
                          onTap: _showMonthYearPicker,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormatter.formatMonthYear(_selectedMonth),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textPrimary),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary),
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Cari transaksi...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: ['Semua', 'Pemasukan', 'Pengeluaran'].map((filter) {
                        final selected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedFilter = filter),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color:
                                  selected ? Colors.white : AppColors.textSecondary,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
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
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Transaction list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        top: AppSpacing.sm,
                        bottom: 120, // Spacing for floating navigation bar
                      ),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final date = grouped.keys.elementAt(index);
                        final items = grouped[date]!;
                        final dayTotal = items.fold<double>(0, (sum, t) {
                          return sum + (t.isIncome ? t.amount : -t.amount);
                        });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    date,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  Text(
                                    '${dayTotal >= 0 ? '+' : ''}${CurrencyFormatter.format(dayTotal)}',
                                    style: TextStyle(
                                      color: dayTotal >= 0
                                          ? AppColors.income
                                          : AppColors.expense,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...items.map(
                              (t) => TransactionItem(
                                transaction: t,
                                onTap: () => TransactionDetailSheet.show(context, t),
                              ),
                            ),
                            if (index < grouped.length - 1)
                              Divider(height: 32, color: Colors.white.withOpacity(0.04)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Urutkan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.base),
            _sortOption(context, Icons.access_time_rounded, 'Terbaru'),
            _sortOption(context, Icons.history_rounded, 'Terlama'),
            _sortOption(
                context, Icons.arrow_upward_rounded, 'Nominal Terbesar'),
            _sortOption(
                context, Icons.arrow_downward_rounded, 'Nominal Terkecil'),
            const SizedBox(height: AppSpacing.base),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(BuildContext context, IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      onTap: () => Navigator.pop(context),
    );
  }
}
