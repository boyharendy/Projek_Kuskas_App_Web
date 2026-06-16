import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String categoryName;
  final IconData categoryIcon;
  final String description;
  final DateTime transactionDate;
  final String paymentMethod;
  final String inputMethod; // 'voice' or 'manual'
  final String? voiceRawText;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryName,
    required this.categoryIcon,
    required this.description,
    required this.transactionDate,
    required this.paymentMethod,
    required this.inputMethod,
    this.voiceRawText,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    IconData getIconForCategory(String categoryName) {
      // Map basic categories or return a default icon
      switch (categoryName) {
        case 'Makanan & Minuman':
        case 'Konsumsi & Belanja':
          return Icons.fastfood_rounded;
        case 'Transportasi':
          return Icons.directions_car_rounded;
        case 'Tagihan & Utilitas':
        case 'Tagihan & Kewajiban':
          return Icons.bolt_rounded;
        case 'Gaji':
        case 'Penghasilan Utama':
          return Icons.monetization_on_rounded;
        case 'Freelance':
        case 'Penghasilan Tambahan':
          return Icons.add_card_rounded;
        case 'Investasi & Lainnya':
          return Icons.trending_up_rounded;
        case 'Gaya Hidup':
        case 'Hiburan':
          return Icons.sports_esports_rounded;
        case 'Kesehatan & Edukasi':
          return Icons.health_and_safety_rounded;
        default:
          return Icons.category_rounded;
      }
    }

    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      categoryName: json['category_name'],
      categoryIcon: getIconForCategory(json['category_name']),
      description: json['description'] ?? json['category_name'],
      transactionDate: DateTime.parse(json['transaction_date']),
      paymentMethod: json['payment_method'],
      inputMethod: json['input_method'],
      voiceRawText: json['voice_raw_text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'category_name': categoryName,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      'payment_method': paymentMethod,
      'input_method': inputMethod,
      'voice_raw_text': voiceRawText,
      // 'id' and 'created_at' and 'updated_at' and 'user_id' are handled by Supabase
    };
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  /// Dummy data for UI development
  static List<Transaction> dummyData = [
    Transaction(
      id: '1',
      type: 'expense',
      amount: 50000,
      categoryName: 'Makanan & Minuman',
      categoryIcon: Icons.fastfood_rounded,
      description: 'Makan siang di warteg',
      transactionDate: DateTime.now(),
      paymentMethod: 'cash',
      inputMethod: 'voice',
      voiceRawText: 'makan siang 50 ribu',
      createdAt: DateTime.now(),
    ),
    Transaction(
      id: '2',
      type: 'income',
      amount: 5000000,
      categoryName: 'Gaji',
      categoryIcon: Icons.monetization_on_rounded,
      description: 'Gaji bulan Juni',
      transactionDate: DateTime.now().subtract(const Duration(days: 1)),
      paymentMethod: 'bank_transfer',
      inputMethod: 'manual',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '3',
      type: 'expense',
      amount: 350000,
      categoryName: 'Tagihan & Utilitas',
      categoryIcon: Icons.bolt_rounded,
      description: 'Bayar listrik',
      transactionDate: DateTime.now().subtract(const Duration(days: 1)),
      paymentMethod: 'e_wallet',
      inputMethod: 'manual',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '4',
      type: 'expense',
      amount: 100000,
      categoryName: 'Transportasi',
      categoryIcon: Icons.directions_car_rounded,
      description: 'Isi bensin motor',
      transactionDate: DateTime.now().subtract(const Duration(days: 2)),
      paymentMethod: 'cash',
      inputMethod: 'voice',
      voiceRawText: 'isi bensin 100 ribu',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: '5',
      type: 'income',
      amount: 1500000,
      categoryName: 'Freelance',
      categoryIcon: Icons.work_rounded,
      description: 'Project desain logo',
      transactionDate: DateTime.now().subtract(const Duration(days: 2)),
      paymentMethod: 'bank_transfer',
      inputMethod: 'manual',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: '6',
      type: 'expense',
      amount: 25000,
      categoryName: 'Makanan & Minuman',
      categoryIcon: Icons.fastfood_rounded,
      description: 'Kopi dan roti',
      transactionDate: DateTime.now().subtract(const Duration(days: 3)),
      paymentMethod: 'e_wallet',
      inputMethod: 'manual',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Transaction(
      id: '7',
      type: 'expense',
      amount: 200000,
      categoryName: 'Belanja',
      categoryIcon: Icons.shopping_cart_rounded,
      description: 'Belanja bulanan',
      transactionDate: DateTime.now().subtract(const Duration(days: 4)),
      paymentMethod: 'debit_card',
      inputMethod: 'manual',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Transaction(
      id: '8',
      type: 'expense',
      amount: 75000,
      categoryName: 'Hiburan',
      categoryIcon: Icons.sports_esports_rounded,
      description: 'Nonton bioskop',
      transactionDate: DateTime.now().subtract(const Duration(days: 5)),
      paymentMethod: 'e_wallet',
      inputMethod: 'voice',
      voiceRawText: 'nonton bioskop 75 ribu',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}
