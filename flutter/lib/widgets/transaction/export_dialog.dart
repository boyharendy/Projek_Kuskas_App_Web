import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_generator.dart';
import '../../utils/excel_generator.dart';
import '../../utils/file_saver.dart';

class ExportDialog extends StatefulWidget {
  final String format; // 'pdf' or 'excel'

  const ExportDialog({super.key, required this.format});

  /// Displays the export bottom sheet
  static void show(BuildContext context, {required String format}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportDialog(format: format),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _selectedScope = 'monthly'; // 'monthly', 'yearly', 'all'
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  List<int> get _yearList {
    final currentYear = DateTime.now().year;
    return List<int>.generate(8, (index) => (currentYear - 5) + index);
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = widget.format == 'pdf';
    final actionColor = isPdf ? AppColors.accent : AppColors.income;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0x1AFFFFFF), width: 1.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.grid_on_rounded,
                    color: actionColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  isPdf ? 'Ekspor Laporan PDF' : 'Ekspor Laporan Excel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Scope Selector Label
            const Text(
              'Pilih Rentang Waktu Laporan:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Scope Segmented Chips Row
            Row(
              children: [
                _buildScopeChip('monthly', 'Bulanan'),
                const SizedBox(width: 8),
                _buildScopeChip('yearly', 'Tahunan'),
                const SizedBox(width: 8),
                _buildScopeChip('all', 'Semua Data'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Dynamic Selectors Panel
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildDynamicInputsPanel(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Action Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: Color(0x1AFFFFFF), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Export Button (Fuchsia Gradient for PDF, Green for Excel)
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _handleExport(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? null
                            : LinearGradient(
                                colors: isPdf
                                    ? AppColors.accentGradient
                                    : [AppColors.income, AppColors.income.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: _isLoading ? Colors.white.withOpacity(0.08) : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: actionColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Ekspor Laporan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeChip(String scope, String label) {
    final isSelected = _selectedScope == scope;
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading ? null : () => setState(() => _selectedScope = scope),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0x1F0F1532),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryLight : const Color(0x1AFFFFFF),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicInputsPanel() {
    final dropdownDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0x1F0F1532),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    );

    if (_selectedScope == 'monthly') {
      return Row(
        key: const ValueKey('monthly_panel'),
        children: [
          // Month Dropdown
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Bulan:', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: _selectedMonth,
                  decoration: dropdownDecoration,
                  dropdownColor: AppColors.surface,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(_monthNames[index], style: const TextStyle(color: Colors.white, fontSize: 14)),
                    );
                  }),
                  onChanged: _isLoading ? null : (val) {
                    if (val != null) setState(() => _selectedMonth = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Year Dropdown
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Tahun:', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: dropdownDecoration,
                  dropdownColor: AppColors.surface,
                  items: _yearList.map((y) {
                    return DropdownMenuItem<int>(
                      value: y,
                      child: Text(y.toString(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: _isLoading ? null : (val) {
                    if (val != null) setState(() => _selectedYear = val);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    } else if (_selectedScope == 'yearly') {
      return Column(
        key: const ValueKey('yearly_panel'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Tahun:', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          const SizedBox(height: 6),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: dropdownDecoration,
              dropdownColor: AppColors.surface,
              items: _yearList.map((y) {
                return DropdownMenuItem<int>(
                  value: y,
                  child: Text(y.toString(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                );
              }).toList(),
              onChanged: _isLoading ? null : (val) {
                if (val != null) setState(() => _selectedYear = val);
              },
            ),
          ),
        ],
      );
    } else {
      return Container(
        key: const ValueKey('all_panel'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Seluruh riwayat catatan keuangan Anda dari awal pembentukan akun akan dicetak ke dalam laporan.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User tidak terautentikasi');
      }

      DateTime? startDate;
      DateTime? endDate;
      String periodLabel = '';

      if (_selectedScope == 'monthly') {
        startDate = DateTime(_selectedYear, _selectedMonth, 1);
        endDate = DateTime(_selectedYear, _selectedMonth + 1, 1);
        periodLabel = '${_monthNames[_selectedMonth - 1]} $_selectedYear';
      } else if (_selectedScope == 'yearly') {
        startDate = DateTime(_selectedYear, 1, 1);
        endDate = DateTime(_selectedYear + 1, 1, 1);
        periodLabel = 'Tahun $_selectedYear';
      } else {
        periodLabel = 'Semua Riwayat';
      }

      // Query database
      var query = Supabase.instance.client
          .from('transactions')
          .select()
          .eq('user_id', userId);

      if (startDate != null && endDate != null) {
        query = query
            .gte('transaction_date', startDate.toIso8601String())
            .lt('transaction_date', endDate.toIso8601String());
      }

      final response = await query.order('transaction_date', ascending: false);
      final transactions = (response as List).map((json) => Transaction.fromJson(json)).toList();

      if (transactions.isEmpty) {
        throw Exception('Tidak ada transaksi ditemukan untuk periode $periodLabel');
      }

      final totalIncome = transactions
          .where((t) => t.isIncome)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final totalExpense = transactions
          .where((t) => t.isExpense)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final balance = totalIncome - totalExpense;

      List<int> bytes;
      String filename;
      String mimeType;

      if (widget.format == 'pdf') {
        bytes = await PdfGenerator.generateReport(
          transactions: transactions,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          balance: balance,
          periodName: periodLabel,
        );
        filename = 'Kuskas_Laporan_${periodLabel.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        mimeType = 'application/pdf';
      } else {
        bytes = await ExcelGenerator.generateReport(
          transactions: transactions,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          balance: balance,
          periodName: periodLabel,
        );
        filename = 'Kuskas_Laporan_${periodLabel.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      }

      await FileSaver.saveAndDownload(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan berhasil diunduh: $filename'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor laporan: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
