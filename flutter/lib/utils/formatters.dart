import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat('#,###', 'id_ID');

  static String format(double amount) {
    return 'Rp ${_formatter.format(amount.toInt())}';
  }

  static String formatNoSymbol(double amount) {
    return _formatter.format(amount.toInt());
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000000000) {
      final val = amount / 1000000000000;
      return 'Rp ${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}T';
    } else if (amount >= 1000000000) {
      final val = amount / 1000000000;
      return 'Rp ${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      final val = amount / 1000000;
      return 'Rp ${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      final val = amount / 1000;
      return 'Rp ${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(0)}rb';
    }
    return format(amount);
  }

  static String formatCompactNoSymbol(double amount) {
    if (amount >= 1000000000000) {
      final val = amount / 1000000000000;
      return '${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}T';
    } else if (amount >= 1000000000) {
      final val = amount / 1000000000;
      return '${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      final val = amount / 1000000;
      return '${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      final val = amount / 1000;
      return '${val % 1 == 0 ? val.toInt() : val.toStringAsFixed(0)}rb';
    }
    return amount.toInt().toString();
  }
}

class DateFormatter {
  static String formatFull(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String formatDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hari ini';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatShort(date);
  }
}
