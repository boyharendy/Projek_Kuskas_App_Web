import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../models/transaction.dart' as model;
import '../widgets/dashboard/summary_cards.dart';
import '../widgets/dashboard/recent_transactions.dart';
import '../utils/transaction_notifier.dart';
import '../widgets/dashboard/notification_center_sheet.dart';
import '../utils/user_cache.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    TransactionNotifier.notifier.addListener(_fetchUnreadCount);
  }

  @override
  void dispose() {
    TransactionNotifier.notifier.removeListener(_fetchUnreadCount);
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final response = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_processed', false);
          
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = (response as List).length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: ValueListenableBuilder<int>(
          valueListenable: UserCache.updateNotifier,
          builder: (context, _, __) {
            final displayName = UserCache.displayName ?? 'Kuskas User';
            final avatarIndex = UserCache.avatarIndex;
            final avatarBase64 = UserCache.avatarBase64;

            final List<Color> gradientColors;
            if (avatarIndex == 0) {
              gradientColors = AppColors.primaryGradient;
            } else if (avatarIndex == 1) {
              gradientColors = AppColors.accentGradient;
            } else if (avatarIndex == 2) {
              gradientColors = AppColors.secondaryGradient;
            } else if (avatarIndex == 3) {
              gradientColors = [AppColors.income, Colors.tealAccent];
            } else {
              gradientColors = AppColors.primaryGradient;
            }

            final ImageProvider? avatarImage = (avatarIndex == -1 && avatarBase64 != null)
                ? MemoryImage(base64Decode(avatarBase64))
                : null;

            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile').then((_) => setState(() {})),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF0F1532),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selamat datang 👋',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                onPressed: () {
                  NotificationCenterSheet.show(context, () {
                    _fetchUnreadCount();
                    setState(() {});
                  });
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.expense,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$_unreadNotificationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: TransactionNotifier.notifier,
        builder: (context, _, __) {
          return FutureBuilder<List<model.Transaction>>(
            future: _fetchTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final transactions = snapshot.data ?? [];
              final totalIncome = transactions
                  .where((t) => t.isIncome)
                  .fold<double>(0, (sum, t) => sum + t.amount);
              final totalExpense = transactions
                  .where((t) => t.isExpense)
                  .fold<double>(0, (sum, t) => sum + t.amount);
              final balance = totalIncome - totalExpense;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Ringkasan Keuangan Anda',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Summary cards (Balance & Action Buttons)
                    SummaryCards(
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      balance: balance,
                      onTransactionAdded: () {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Recent transactions
                    RecentTransactions(transactions: transactions.take(5).toList()),
                    const SizedBox(height: 120), // Spacing for floating navigation bar
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
