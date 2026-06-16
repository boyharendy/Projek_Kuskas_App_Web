import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'KUSKAS';
  static const String appTagline = 'Catat Keuanganmu dengan Suara';
  static const String currency = 'Rp';
  static const String locale = 'id_ID';
}

class CategoryData {
  final String name;
  final IconData icon;
  final String type; // 'income' or 'expense'

  const CategoryData({
    required this.name,
    required this.icon,
    required this.type,
  });

  static const List<CategoryData> expenseCategories = [
    CategoryData(name: 'Konsumsi & Belanja', icon: Icons.shopping_basket_rounded, type: 'expense'),
    CategoryData(name: 'Tagihan & Kewajiban', icon: Icons.receipt_long_rounded, type: 'expense'),
    CategoryData(name: 'Transportasi', icon: Icons.directions_car_rounded, type: 'expense'),
    CategoryData(name: 'Gaya Hidup', icon: Icons.sports_esports_rounded, type: 'expense'),
    CategoryData(name: 'Kesehatan & Edukasi', icon: Icons.health_and_safety_rounded, type: 'expense'),
    CategoryData(name: 'Lainnya', icon: Icons.more_horiz_rounded, type: 'expense'),
  ];

  static const List<CategoryData> incomeCategories = [
    CategoryData(name: 'Penghasilan Utama', icon: Icons.monetization_on_rounded, type: 'income'),
    CategoryData(name: 'Penghasilan Tambahan', icon: Icons.add_card_rounded, type: 'income'),
    CategoryData(name: 'Investasi & Lainnya', icon: Icons.trending_up_rounded, type: 'income'),
  ];

  static List<CategoryData> getByType(String type) {
    return type == 'income' ? incomeCategories : expenseCategories;
  }
}

class PaymentMethod {
  final String id;
  final String label;
  final IconData icon;

  const PaymentMethod({
    required this.id,
    required this.label,
    required this.icon,
  });

  static const List<PaymentMethod> methods = [
    PaymentMethod(id: 'cash', label: 'Cash', icon: Icons.payments_rounded),
    PaymentMethod(id: 'bank_transfer', label: 'Transfer Bank', icon: Icons.account_balance_rounded),
    PaymentMethod(id: 'e_wallet', label: 'E-Wallet', icon: Icons.account_balance_wallet_rounded),
    PaymentMethod(id: 'credit_card', label: 'Kartu Kredit', icon: Icons.credit_card_rounded),
    PaymentMethod(id: 'debit_card', label: 'Kartu Debit', icon: Icons.credit_card_rounded),
    PaymentMethod(id: 'other', label: 'Lainnya', icon: Icons.more_horiz_rounded),
  ];
}
