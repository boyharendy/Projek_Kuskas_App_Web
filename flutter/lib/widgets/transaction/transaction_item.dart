import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF), // Very subtle glassy overlay (4% white)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Circular Icon with glassy gradient ring
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (transaction.isIncome ? AppColors.income : AppColors.expense)
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (transaction.isIncome ? AppColors.income : AppColors.expense)
                        .withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    transaction.categoryIcon,
                    size: 20,
                    color: transaction.isIncome ? AppColors.income : AppColors.expense,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.description.isNotEmpty 
                        ? transaction.description 
                        : transaction.paymentMethod,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                    style: TextStyle(
                      color: transaction.isIncome ? AppColors.income : AppColors.expense,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (transaction.inputMethod == 'voice')
                    const Icon(Icons.mic_rounded, size: 14, color: AppColors.primaryLight)
                  else
                    Icon(Icons.edit_rounded, size: 12, color: Colors.white.withOpacity(0.4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
