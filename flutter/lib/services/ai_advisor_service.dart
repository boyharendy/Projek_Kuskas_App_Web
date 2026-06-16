import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class AIAdvisorService {
  /// Mendapatkan ulasan keuangan dan tips perbaikan secara real-time dari Gemini
  /// dengan fallback analisis lokal jika API gagal atau tidak dikonfigurasi.
  static Future<Map<String, dynamic>> getFinancialAdvice({
    required double totalIncome,
    required double totalExpense,
    required List<Transaction> transactions,
    required String period,
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your-gemini-api-key') {
        debugPrint('Gemini API Key tidak valid atau kosong, menggunakan fallback lokal.');
        return _getLocalHeuristicAdvice(totalIncome, totalExpense, transactions, period);
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      // Hitung rincian pengeluaran per kategori untuk memberikan konteks lebih baik ke AI
      final expenseByCategory = <String, double>{};
      for (final t in transactions) {
        if (t.isExpense) {
          expenseByCategory[t.categoryName] = (expenseByCategory[t.categoryName] ?? 0.0) + t.amount;
        }
      }

      // Urutkan kategori berdasarkan pengeluaran terbesar
      final sortedCategories = expenseByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final buffer = StringBuffer();
      if (sortedCategories.isEmpty) {
        buffer.write('- Tidak ada pengeluaran tercatat\n');
      } else {
        for (final entry in sortedCategories) {
          buffer.write('- ${entry.key}: Rp ${entry.value.toInt()}\n');
        }
      }

      final prompt = '''
Anda adalah "Asisten KUSKAS", seorang penasihat keuangan pribadi cerdas dan ramah.
Tugas Anda adalah menganalisis data keuangan pengguna dan memberikan ulasan serta saran perbaikan keuangan yang konkret dalam Bahasa Indonesia.

Jangka Waktu Analisis: $period
Total Pemasukan: Rp ${totalIncome.toInt()}
Total Pengeluaran: Rp ${totalExpense.toInt()}
Saldo Bersih (Pemasukan - Pengeluaran): Rp ${(totalIncome - totalExpense).toInt()}

Rincian Pengeluaran per Kategori:
${buffer.toString()}

Kembalikan HANYA objek JSON yang valid tanpa markdown ```json atau teks tambahan lainnya. Objek JSON harus memiliki struktur persis seperti ini:
{
  "status": "Sangat Sehat", 
  "statusColor": "green", 
  "commentary": "Tulis ulasan singkat (2-3 kalimat) tentang kondisi keuangan pengguna. Bersikaplah suportif dan berikan analisis logis berdasarkan perbandingan pemasukan vs pengeluaran serta kategori terbesar.",
  "tips": [
    "Tulis saran konkret ke-1 (tindakan nyata, misal: batasi pengeluaran kategori tertentu atau tips menabung)",
    "Tulis saran konkret ke-2",
    "Tulis saran konkret ke-3"
  ]
}

PENTING:
- Gunakan pilihan status berikut:
  * "Sangat Sehat" (statusColor: "green") jika menabung > 40% pemasukan dan tidak ada defisit.
  * "Cukup Baik" (statusColor: "blue") jika masih surplus tapi tabungan di bawah 40%.
  * "Perlu Perhatian" (statusColor: "orange") jika pengeluaran melampaui pemasukan (defisit) atau hampir habis.
  * "Belum Ada Data" (statusColor: "blue") jika pemasukan dan pengeluaran nol.
- Tuliskan setiap nominal uang di dalam teks "commentary" menggunakan format Rupiah dengan pemisah ribuan titik (contoh: "Rp 50.000", "Rp 1.500.000" dan BUKAN "Rp 50000" atau "1000000").
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText != null) {
        // Bersihkan markdown backticks jika ada
        String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = json.decode(cleanJson);
        
        // Pastikan format data lengkap
        if (data.containsKey('status') && data.containsKey('statusColor') && data.containsKey('commentary') && data.containsKey('tips')) {
          return data;
        }
      }
      
      throw Exception('Format respons AI tidak valid');
    } catch (e) {
      debugPrint('Error memanggil Gemini untuk saran keuangan: $e. Menggunakan fallback lokal.');
      return _getLocalHeuristicAdvice(totalIncome, totalExpense, transactions, period);
    }
  }

  /// Analisis aturan heuristik lokal sebagai fallback tangguh
  static Map<String, dynamic> _getLocalHeuristicAdvice(
    double totalIncome,
    double totalExpense,
    List<Transaction> transactions,
    String period,
  ) {
    if (totalIncome == 0 && totalExpense == 0) {
      return {
        "status": "Belum Ada Data",
        "statusColor": "blue",
        "commentary": "Belum ada transaksi tercatat untuk periode $period. Mulai catat transaksi Anda untuk melihat analisis asisten!",
        "tips": [
          "Gunakan fitur suara Kuskas untuk mencatat transaksi dengan cepat.",
          "Coba catat pengeluaran rutin harian Anda.",
          "Tetapkan anggaran pengeluaran bulanan di awal."
        ]
      };
    }

    final balance = totalIncome - totalExpense;

    // Hitung rincian pengeluaran per kategori
    final expenseByCategory = <String, double>{};
    for (final t in transactions) {
      if (t.isExpense) {
        expenseByCategory[t.categoryName] = (expenseByCategory[t.categoryName] ?? 0.0) + t.amount;
      }
    }

    // Cari kategori dengan pengeluaran terbesar
    String largestCategory = 'Lainnya';
    double maxCategoryAmount = 0.0;
    expenseByCategory.forEach((cat, amt) {
      if (amt > maxCategoryAmount) {
        maxCategoryAmount = amt;
        largestCategory = cat;
      }
    });

    if (balance < 0) {
      // Defisit
      return {
        "status": "Perlu Perhatian",
        "statusColor": "orange",
        "commentary": "Keuangan Anda mengalami defisit sebesar ${CurrencyFormatter.format(balance.abs())} pada periode $period. Pengeluaran Anda lebih besar dari pemasukan, yang dapat mengganggu tabungan jangka panjang.",
        "tips": [
          "Batasi pengeluaran di kategori '$largestCategory' yang saat ini menjadi pengeluaran terbesar Anda.",
          "Tunda pengeluaran non-primer (gaya hidup, belanja opsional) hingga kondisi keuangan membaik.",
          "Buat anggaran bulanan yang ketat dan patuhi batas pengeluaran tersebut."
        ]
      };
    }

    // Surplus
    final savingsRate = totalIncome > 0 ? (balance / totalIncome) : 0.0;

    if (savingsRate >= 0.40) {
      return {
        "status": "Sangat Sehat",
        "statusColor": "green",
        "commentary": "Luar biasa! Kondisi keuangan Anda di periode $period sangat sehat dengan tingkat tabungan mencapai ${(savingsRate * 100).toInt()}%. Anda mengelola arus kas dengan sangat baik.",
        "tips": [
          "Pertahankan kebiasaan hemat ini dan alokasikan kelebihan dana ke investasi produktif.",
          "Pastikan dana darurat Anda (setara 3-6 bulan pengeluaran) sudah terisi penuh.",
          "Tentukan tujuan keuangan jangka panjang seperti dana pensiun atau rumah."
        ]
      };
    } else {
      return {
        "status": "Cukup Baik",
        "statusColor": "blue",
        "commentary": "Kondisi keuangan Anda tergolong stabil dengan sisa saldo surplus ${CurrencyFormatter.format(balance)} (${(savingsRate * 100).toInt()}% tabungan). Masih ada ruang untuk mengoptimalkan sisa dana.",
        "tips": [
          "Coba kurangi sedikit pengeluaran pada kategori '$largestCategory' untuk meningkatkan rasio tabungan.",
          "Targetkan untuk menabung minimal 20% dari total pemasukan Anda setiap periode.",
          "Lacak pengeluaran kecil harian yang sering kali tidak disadari (latte factor)."
        ]
      };
    }
  }
}
