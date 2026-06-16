import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart';
import '../transaction/transaction_item.dart';
import '../transaction/transaction_detail_sheet.dart';
import '../../screens/transaction_history_screen.dart';
import '../../navigation/main_navigation.dart';

class RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;

  const RecentTransactions({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terakhir',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                MainNavigation.selectedIndexNotifier.value = 1;
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text('Belum ada transaksi.'),
            ),
          )
        else
          ...transactions.map((t) => TransactionItem(
                transaction: t,
                onTap: () {
                  TransactionDetailSheet.show(context, t);
                },
              )),
      ],
    );
  }
}
