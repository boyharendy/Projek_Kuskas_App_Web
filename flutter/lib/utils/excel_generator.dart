import 'package:excel/excel.dart';
import '../models/transaction.dart';
import 'formatters.dart';

class ExcelGenerator {
  /// Generates a styled Excel sheet of transactions
  static Future<List<int>> generateReport({
    required List<Transaction> transactions,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required String periodName,
  }) async {
    final excel = Excel.createExcel();
    
    // Rename default sheet to 'Laporan Keuangan'
    final sheetName = 'Laporan Keuangan';
    final defaultSheetName = excel.sheets.keys.first;
    excel.rename(defaultSheetName, sheetName);
    final sheet = excel[sheetName];

    // Define cell styles
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#4F46E5'),
    );

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4F46E5'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Left,
    );

    final summaryLabelStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#F8FAFC'),
    );

    // Title Block
    sheet.appendRow([TextCellValue('KUSKAS - LAPORAN RINGKASAN KEUANGAN')]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

    sheet.appendRow([TextCellValue('Periode: $periodName')]);
    sheet.appendRow([TextCellValue('Dicetak pada: ${DateFormatter.formatDay(DateTime.now())}')]);
    sheet.appendRow(<CellValue>[]); // Spacer Row

    // Executive Summary
    sheet.appendRow([TextCellValue('Ringkasan Eksekutif')]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#1E293B'),
    );
    
    sheet.appendRow([TextCellValue('Total Pemasukan'), DoubleCellValue(totalIncome)]);
    sheet.appendRow([TextCellValue('Total Pengeluaran'), DoubleCellValue(totalExpense)]);
    sheet.appendRow([TextCellValue('Saldo Bersih'), DoubleCellValue(balance)]);
    
    // Style the summary rows
    for (int row = 5; row <= 7; row++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).cellStyle = summaryLabelStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).cellStyle = CellStyle(bold: true);
    }
    
    sheet.appendRow(<CellValue>[]); // Spacer Row
    sheet.appendRow(<CellValue>[]); // Spacer Row

    // Transaction Details Header
    final headers = ['Tanggal', 'Kategori', 'Keterangan', 'Metode Pembayaran', 'Jenis', 'Nominal'];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    final int headerRowIdx = 10;
    
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIdx)).cellStyle = headerStyle;
    }

    // Append Transactions
    for (final t in transactions) {
      sheet.appendRow([
        TextCellValue(DateFormatter.formatDay(t.transactionDate)),
        TextCellValue(t.categoryName),
        TextCellValue(t.description.isNotEmpty ? t.description : '-'),
        TextCellValue(t.paymentMethod.toUpperCase().replaceAll('_', ' ')),
        TextCellValue(t.isIncome ? 'Pemasukan' : 'Pengeluaran'),
        DoubleCellValue(t.isIncome ? t.amount : -t.amount),
      ]);
    }

    return excel.encode()!;
  }
}
