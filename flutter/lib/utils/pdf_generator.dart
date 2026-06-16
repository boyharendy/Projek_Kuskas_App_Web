import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/transaction.dart';
import 'formatters.dart';

class PdfGenerator {
  /// Generates a styled PDF report of transactions
  static Future<List<int>> generateReport({
    required List<Transaction> transactions,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required String periodName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KUSKAS',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#6366F1'),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Laporan Ringkasan Keuangan Personal',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromHex('#64748B'),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Periode: $periodName',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0F172A'),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Dicetak: ${DateFormatter.formatDay(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromHex('#94A3B8'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 1),
              ),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(color: PdfColor.fromHex('#F1F5F9'), thickness: 1),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Kuskas Financial Assistant',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#94A3B8'),
                    ),
                  ),
                  pw.Text(
                    'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#94A3B8'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 12),
            
            // Executive Summary Cards Row
            pw.Row(
              children: [
                _buildSummaryCard(
                  'Total Pemasukan',
                  totalIncome,
                  PdfColor.fromHex('#10B981'),
                  PdfColor.fromHex('#064E3B'),
                ),
                pw.SizedBox(width: 12),
                _buildSummaryCard(
                  'Total Pengeluaran',
                  totalExpense,
                  PdfColor.fromHex('#EF4444'),
                  PdfColor.fromHex('#7F1D1D'),
                ),
                pw.SizedBox(width: 12),
                _buildSummaryCard(
                  'Saldo Bersih',
                  balance,
                  PdfColor.fromHex('#3B82F6'),
                  PdfColor.fromHex('#1E3A8A'),
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Transactions Section Title
            pw.Text(
              'Rincian Transaksi',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#0F172A'),
              ),
            ),
            pw.SizedBox(height: 10),

            // Main Data Table
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Kategori', 'Keterangan', 'Metode', 'Jenis', 'Nominal'],
              data: transactions.map((t) {
                return [
                  DateFormatter.formatDay(t.transactionDate),
                  t.categoryName,
                  t.description.isNotEmpty ? t.description : '-',
                  t.paymentMethod.toUpperCase().replaceAll('_', ' '),
                  t.isIncome ? 'Pemasukan' : 'Pengeluaran',
                  '${t.isIncome ? '+' : '-'}${CurrencyFormatter.format(t.amount)}',
                ];
              }).toList(),
              border: null,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#4F46E5'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
              oddRowDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                border: const pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                5: pw.Alignment.centerRight, // Align currency amount to right
              },
              cellStyle: const pw.TextStyle(fontSize: 8.5, color: PdfColors.black),
              headerAlignments: {
                5: pw.Alignment.centerRight,
              },
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryCard(
    String title,
    double amount,
    PdfColor primaryColor,
    PdfColor secondaryColor,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8FAFC'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromHex('#64748B'),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              CurrencyFormatter.format(amount),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
