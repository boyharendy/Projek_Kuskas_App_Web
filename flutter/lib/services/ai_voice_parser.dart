import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIVoiceParser {
  /// Menerima teks bahasa alami (misal: "Saya beli jajan 50 ribu")
  /// dan mengembalikan Map yang berisi hasil parsing.
  static Future<Map<String, dynamic>?> parseTransaction(String text) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your-gemini-api-key') {
        throw Exception("API Key Gemini belum diatur di .env");
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final prompt = '''
Anda adalah asisten pencatat keuangan pintar untuk aplikasi Kuskas.
Tugas Anda adalah membaca kalimat transkrip suara pengguna berikut, mengekstrak informasi transaksi keuangan dari sudut pandang PENGGUNA (pemilik akun), dan mengembalikannya HANYA dalam format JSON yang valid tanpa markdown tambahan.

PANDUAN KLASIFIKASI TRANSAKSI:
1. Pemasukan (type: "income"):
   - Jika pengguna MENERIMA uang, MENDAPATKAN dana/transfer, DIBERI uang, dikasih hadiah uang, atau orang lain MEMBAYAR UTANG kepada pengguna (contoh: "Roni memberikan uang ke saya", "dapat transferan", "mengembalikan uang saya", "bapak ngasih uang", "dia bayar utang ke saya karena dia berhutang").
   - Kategori Pemasukan yang tersedia: "Penghasilan Utama" (untuk gaji, hasil dagang utama), "Penghasilan Tambahan" (sampingan, diberi orang, bayar utang dari orang lain), "Investasi & Lainnya" (bunga bank, investasi, cashback, dll.).
2. Pengeluaran (type: "expense"):
   - Jika pengguna MENGELUARKAN uang, MEMBELI barang/jasa, MEMBAYAR tagihan, atau MEMBAYAR UTANG kepada orang lain (contoh: "saya bayar utang ke Roni", "beli makan", "transfer ke ibu").
   - Kategori Pengeluaran yang tersedia: "Konsumsi & Belanja", "Tagihan & Kewajiban", "Transportasi", "Gaya Hidup", "Kesehatan & Edukasi", "Lainnya".

PANDUAN METODE PEMBAYARAN (paymentMethod):
- cash (jika cash/tunai/dikasih langsung tangan ke tangan atau tidak menyebutkan dompet digital/bank)
- bank_transfer (jika menyebut transfer bank, m-banking, seabank, bca, mandiri, dll.)
- e_wallet (jika menyebut e-wallet, dana, gopay, ovo, shopeepay, linkaja, dll.)
- credit_card (jika menyebut kartu kredit)
- debit_card (jika menyebut kartu debit/gesek kartu)
- other (jika tidak disebutkan secara spesifik)

Format Output JSON yang diharapkan:
{
  "type": "expense" atau "income",
  "amount": 50000, // angka nominal lengkap tanpa singkatan
  "categoryName": "Pilih salah satu kategori di atas yang paling sesuai",
  "paymentMethod": "Metode pembayaran di atas",
  "description": "Ringkasan deskripsi transaksi yang padat dan jelas (maks 5 kata)"
}

Kalimat Pengguna: "$text"
''';

      try {
        final response = await model.generateContent([
          Content.text(prompt)
        ]);
        final responseText = response.text;

        if (responseText != null) {
          // Bersihkan markdown backticks jika ada
          String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
          final Map<String, dynamic> data = json.decode(cleanJson);
          
          // --- FORCE PAYMENT METHOD EXTRACTION ---
          // Gemini kadang-kadang lupa memberikan paymentMethod, jadi kita pastikan
          // dengan membaca langsung dari teks aslinya!
          final lowerText = text.toLowerCase();
          if (lowerText.contains('e-wallet') || lowerText.contains('ewallet') || lowerText.contains('gopay') || lowerText.contains('ovo') || lowerText.contains('dana')) {
            data['paymentMethod'] = 'e_wallet';
          } else if (lowerText.contains('transfer') || lowerText.contains('bank')) {
            data['paymentMethod'] = 'bank_transfer';
          } else if (lowerText.contains('kredit') || lowerText.contains('credit')) {
            data['paymentMethod'] = 'credit_card';
          } else if (lowerText.contains('debit')) {
            data['paymentMethod'] = 'debit_card';
          } else if (data['paymentMethod'] != null) {
            // Normalisasi output AI jika ada typo
            String pm = data['paymentMethod'].toString().toLowerCase().replaceAll('-', '_');
            if (pm == 'ewallet') pm = 'e_wallet';
            data['paymentMethod'] = pm;
          }

          return data;
        }
      } catch (e) {
        debugPrint('Gemini API Error: $e');
        
        // --- SMART FALLBACK ---
        // Jika AI gagal (baik karena API Key salah, atau server sedang 503 Overloaded),
        // kita selalu gunakan Regex sederhana ini agar fitur tetap bisa dipakai.
        await Future.delayed(const Duration(milliseconds: 500));
        
        final lowerText = text.toLowerCase();
        String type = 'expense';
        String category = 'Konsumsi & Belanja';
        
        // Cek kata kunci pemasukan yang lebih komprehensif
        bool isIncome = false;
        final incomeKeywords = [
          'gaji', 'pemasukan', 'dapat', 'investasi', 'terima', 'diberi', 
          'dikasih', 'ngasih', 'memberi uang', 'memberikan uang', 'sewa masuk', 
          'bayar utang ke saya', 'dia berhutang', 'dia berutang', 'hutang ke saya', 
          'utang ke saya', 'sebab dia berhutang', 'karena dia berhutang'
        ];
        
        for (final kw in incomeKeywords) {
          if (lowerText.contains(kw)) {
            isIncome = true;
            break;
          }
        }

        if (isIncome) {
          type = 'income';
          category = 'Penghasilan Tambahan';
          if (lowerText.contains('gaji')) {
            category = 'Penghasilan Utama';
          } else if (lowerText.contains('investasi')) {
            category = 'Investasi & Lainnya';
          }
        }

        // Ekstrak angka dari teks (bisa mengandung desimal)
        int amount = 0;
        final numMatch = RegExp(r'(\d+[\d\.,]*)').firstMatch(text);
        if (numMatch != null) {
          String rawNum = numMatch.group(1)!;
          // Normalisasi: jika mengandung desimal koma (misal 1,5 juta)
          if (rawNum.contains(',') && !rawNum.contains('.')) {
            rawNum = rawNum.replaceAll(',', '.');
          } else if (rawNum.contains('.') && rawNum.split('.').last.length < 3) {
            // Jika desimal dengan titik (misal 1.5 juta), biarkan titiknya
          } else {
            // Jika ribuan (misal 50.000), buang pemisah titik/koma
            rawNum = rawNum.replaceAll('.', '').replaceAll(',', '');
          }

          double amountValue = double.tryParse(rawNum) ?? 0.0;
          double multiplier = 1.0;

          if (lowerText.contains('ribu')) {
            if (lowerText.contains('ratus ribu')) {
              multiplier = 100000.0;
            } else {
              multiplier = 1000.0;
            }
          } else if (lowerText.contains('juta')) {
            multiplier = 1000000.0;
          } else if (lowerText.contains('miliar') || lowerText.contains('milyar')) {
            multiplier = 1000000000.0;
          } else if (lowerText.contains('triliun') || lowerText.contains('trilyun')) {
            multiplier = 1000000000000.0;
          }

          amount = (amountValue * multiplier).toInt();
        }
        
        if (amount == 0) amount = 5000; // default jika gagal ekstrak
        
        // Ekstrak payment method
        String paymentMethod = 'cash';
        if (lowerText.contains('e-wallet') || lowerText.contains('ewallet') || lowerText.contains('gopay') || lowerText.contains('ovo') || lowerText.contains('dana')) {
          paymentMethod = 'e_wallet';
        } else if (lowerText.contains('transfer') || lowerText.contains('bank')) {
          paymentMethod = 'bank_transfer';
        } else if (lowerText.contains('kredit')) {
          paymentMethod = 'credit_card';
        } else if (lowerText.contains('debit')) {
          paymentMethod = 'debit_card';
        }
        
        return {
          "type": type,
          "amount": amount,
          "categoryName": category,
          "paymentMethod": paymentMethod,
          "description": text.isNotEmpty ? text : "Transaksi Suara"
        };
      }
    } catch (e) {
      debugPrint('Error parsing voice with Gemini: $e');
      throw Exception('Gagal memproses AI: $e');
    }
  }
}

// Dummy debug print untuk error handling jika tidak impor flutter/foundation
void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
