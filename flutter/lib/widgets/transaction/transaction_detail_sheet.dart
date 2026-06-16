import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';

class TransactionDetailSheet {
  static void show(BuildContext context, Transaction t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
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
              const SizedBox(height: AppSpacing.xl),
              // Category icon & name
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: (t.isIncome
                              ? AppColors.income
                              : AppColors.expense)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: Icon(
                        t.categoryIcon,
                        size: 26,
                        color: t.isIncome ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.categoryName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          t.isIncome ? 'Pemasukan' : 'Pengeluaran',
                          style: TextStyle(
                            color: t.isIncome
                                ? AppColors.income
                                : AppColors.expense,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Amount
              Text(
                '${t.isIncome ? '+' : '-'} ${CurrencyFormatter.format(t.amount)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: t.isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.base),
              _detailRow(context, 'Deskripsi', t.description),
              _detailRow(context, 'Tanggal',
                  DateFormatter.formatFull(t.transactionDate)),
              _detailRow(context, 'Metode Bayar', t.paymentMethod),
              _detailRow(context, 'Input via',
                  t.inputMethod == 'voice' ? 'Suara' : 'Manual'),
              if (t.voiceRawText != null)
                _detailRow(context, 'Teks Suara', '"${t.voiceRawText}"'),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Hapus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
