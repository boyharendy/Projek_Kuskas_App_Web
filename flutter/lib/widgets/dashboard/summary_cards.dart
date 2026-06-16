import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/formatters.dart';
import '../../screens/add_transaction_screen.dart';

class SummaryCards extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final VoidCallback onTransactionAdded;

  const SummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.onTransactionAdded,
  });

  @override
  State<SummaryCards> createState() => _SummaryCardsState();
}

class _SummaryCardsState extends State<SummaryCards> {
  bool _obscureBalance = false;

  @override
  Widget build(BuildContext context) {
    // Calculate simulated trend
    final isPositive = widget.balance >= 0;
    final trendPercent = isPositive ? "12.4%" : "8.2%";
    final trendText = isPositive ? "+$trendPercent" : "-$trendPercent";
    final trendColor = isPositive ? AppColors.income : AppColors.expense;

    return Column(
      children: [
        // 1. Premium Balance Card with Glowing Indigo/Purple Background
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Glowing vector overlay shapes
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Positioned(
                  left: -60,
                  bottom: -60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                
                // Card Contents
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Saldo',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureBalance = !_obscureBalance;
                              });
                            },
                            icon: Icon(
                              _obscureBalance 
                                  ? Icons.visibility_off_rounded 
                                  : Icons.visibility_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _obscureBalance 
                            ? 'Rp ••••••••' 
                            : CurrencyFormatter.format(widget.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPositive 
                                      ? Icons.trending_up_rounded 
                                      : Icons.trending_down_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  trendText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'dibanding bulan lalu',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Action Pill Buttons (Transfer & Request style)
        Row(
          children: [
            // Pemasukan Button (Gradient Emerald Green Pill)
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToAddTransaction(context, 'income'),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF047857)], // Emerald Green Gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Pemasukan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Pengeluaran Button (Gradient Rose Red Pill)
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToAddTransaction(context, 'expense'),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF43F5E), Color(0xFFBE123C)], // Rose Red Gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF43F5E).withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Pengeluaran',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 3. Glassmorphic Income & Expense Cards
        Row(
          children: [
            Expanded(
              child: _buildGlassyStatCard(
                title: 'Total Pemasukan',
                amount: widget.totalIncome,
                icon: Icons.south_west_rounded,
                iconColor: AppColors.income,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGlassyStatCard(
                title: 'Total Pengeluaran',
                amount: widget.totalExpense,
                icon: Icons.north_east_rounded,
                iconColor: AppColors.expense,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _navigateToAddTransaction(BuildContext context, String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );
    if (result == true) {
      widget.onTransactionAdded();
    }
  }

  Widget _buildGlassyStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF), // Transparent white
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatCompact(amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
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
}
