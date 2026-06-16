import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../utils/formatters.dart';

class NotificationCenterSheet extends StatefulWidget {
  const NotificationCenterSheet({super.key});

  static void show(BuildContext context, VoidCallback onClosed) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const NotificationCenterSheet(),
    ).then((_) => onClosed());
  }

  @override
  State<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_processed', false)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = response as List? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _dismissNotification(String notifId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_processed': true, 'is_read': true})
          .eq('id', notifId);
      
      _fetchNotifications();
    } catch (e) {
      debugPrint("Error dismissing notification: $e");
    }
  }

  Future<void> _processNotification(Map<String, dynamic> notif) async {
    final notifId = notif['id'];
    final wallet = notif['wallet'] ?? 'E-Wallet';
    final amount = (notif['amount'] as num?)?.toDouble() ?? 0.0;
    final type = notif['type'] ?? 'income';
    final desc = notif['description'] ?? '';
    final paymentMethod = notif['payment_method'] ?? 'e_wallet';

    // Mark as processed in database first
    await _dismissNotification(notifId);

    if (mounted) {
      Navigator.pop(context); // Close bottom sheet
      
      // Determine category based on wallet type / transaction type
      String? categoryName;
      if (type == 'income') {
        categoryName = (wallet == 'DANA' || wallet == 'OVO' || wallet == 'GoPay' || wallet == 'ShopeePay')
            ? 'Penghasilan Tambahan'
            : 'Penghasilan Utama';
      } else {
        categoryName = 'Lainnya';
      }

      // Open AddTransactionScreen with pre-filled fields
      Navigator.pushNamed(
        context,
        '/add-transaction',
        arguments: {
          'type': type,
          'amount': amount,
          'categoryName': categoryName,
          'description': desc.isNotEmpty ? desc : "Transfer Masuk $wallet",
          'paymentMethod': paymentMethod,
        },
      );
    }
  }

  String _formatTimeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m yang lalu';
      if (diff.inHours < 24) return '${diff.inHours}j yang lalu';
      return '${diff.inDays} hari yang lalu';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.7;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: const Color(0xEC0F1532), // Deep Translucent Navy
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              // Top drag indicator handle
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monitor Notifikasi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_notifications.isNotEmpty)
                      TextButton(
                        onPressed: () async {
                          // Dismiss all
                          try {
                            final userId = Supabase.instance.client.auth.currentUser?.id;
                            if (userId == null) return;
                            await Supabase.instance.client
                                .from('notifications')
                                .update({'is_processed': true, 'is_read': true})
                                .eq('user_id', userId)
                                .eq('is_processed', false);
                            _fetchNotifications();
                          } catch (e) {
                            debugPrint("Error dismissing all: $e");
                          }
                        },
                        child: Text(
                          'Tandai Semua Selesai',
                          style: TextStyle(
                            color: AppColors.primaryLight.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0x14FFFFFF), height: 1),
              
              // Body content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                    : _notifications.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              return _buildNotificationCard(item);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Transaksi Baru',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi dari DANA, OVO, GoPay, SeaBank,\natau m-banking lainnya akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.45),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final wallet = item['wallet'] ?? 'E-Wallet';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final type = item['type'] ?? 'income';
    final desc = item['description'] ?? '';
    final createdAt = item['created_at'] ?? '';
    final isIncome = type == 'income';
    
    final accentColor = isIncome ? AppColors.income : AppColors.expense;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _processNotification(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glowing icon depending on income/expense
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            wallet,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          Text(
                            _formatTimeAgo(createdAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc.isNotEmpty ? desc : "Transaksi terdeteksi dari $wallet",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${isIncome ? '+' : '-'}${CurrencyFormatter.format(amount)}',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                
                // Dismiss action button
                GestureDetector(
                  onTap: () => _dismissNotification(item['id']),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
