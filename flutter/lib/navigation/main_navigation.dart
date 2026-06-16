import 'dart:async' show Timer;
import 'dart:ui' as ui;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/web_notification.dart';
import '../screens/dashboard_screen.dart';
import '../screens/transaction_history_screen.dart';
import '../screens/chart_screen.dart';
import '../screens/news_screen.dart';
import '../config/theme.dart';
import '../widgets/voice/voice_fab.dart';
import '../widgets/animated_background.dart';
import '../services/notification_listener_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  Timer? _reminderTimer;
  String _lastTriggeredDate = '';

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionHistoryScreen(),
    ChartScreen(),
    NewsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = MainNavigation.selectedIndexNotifier.value;
    MainNavigation.selectedIndexNotifier.addListener(_onTabChanged);

    // Initialize transaction notification listener for Android
    final isAndroid = !kIsWeb && Platform.isAndroid;
    if (isAndroid) {
      NotificationListenerService().registerTransactionCallback(_onTransactionDetected);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkLaunchTransaction();
        _syncCredentialsToNative();
      });
    }

    // Start daily reminder timer checks (for Web/foreground platforms)
    _startReminderTimer();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    MainNavigation.selectedIndexNotifier.removeListener(_onTabChanged);
    final isAndroid = !kIsWeb && Platform.isAndroid;
    if (isAndroid) {
      NotificationListenerService().unregisterTransactionCallback();
    }
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _selectedIndex = MainNavigation.selectedIndexNotifier.value;
      });
    }
  }

  Future<void> _syncCredentialsToNative() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      if (url.isNotEmpty && key.isNotEmpty) {
        await NotificationListenerService().syncCredentials(
          url: url,
          key: key,
          userId: userId,
        );
        debugPrint("Supabase credentials synced to Android native");
      }
    } catch (e) {
      debugPrint("Error syncing credentials: $e");
    }
  }

  Future<void> _checkLaunchTransaction() async {
    final txData = await NotificationListenerService().getLaunchTransaction();
    if (txData != null) {
      _onTransactionDetected(txData);
    }
  }

  void _onTransactionDetected(Map<String, dynamic> data) {
    if (!mounted) return;

    final wallet = data['wallet'] as String? ?? 'E-Wallet';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final type = data['type'] as String? ?? 'income';
    final desc = data['desc'] as String? ?? '';

    // Determine category based on wallet type / transaction type
    String? categoryName;
    if (type == 'income') {
      categoryName = (wallet == 'DANA' || wallet == 'OVO' || wallet == 'GoPay' || wallet == 'ShopeePay')
          ? 'Penghasilan Tambahan'
          : 'Penghasilan Utama';
    } else {
      categoryName = 'Lainnya';
    }

    final paymentMethod = (wallet == 'DANA' || wallet == 'OVO' || wallet == 'GoPay' || wallet == 'ShopeePay')
        ? 'e_wallet'
        : 'bank_transfer';

    // Directly open the add-transaction screen with fields pre-filled, as requested by the user
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

  void _startReminderTimer() {
    // Check every 30 seconds
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkReminderTime();
    });
  }

  void _checkReminderTime() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final metadata = user.userMetadata;
    if (metadata == null) return;

    final enabled = metadata['reminder_enabled'] as bool? ?? false;
    if (!enabled) return;

    final hour = metadata['reminder_hour'] as int? ?? 20;
    final minute = metadata['reminder_minute'] as int? ?? 0;

    final now = DateTime.now();
    final currentDateStr = "${now.year}-${now.month}-${now.day}";

    if (now.hour == hour && now.minute == minute && _lastTriggeredDate != currentDateStr) {
      _lastTriggeredDate = currentDateStr;
      _triggerReminderNotification();
    }
  }

  Future<void> _triggerReminderNotification() async {
    if (kIsWeb) {
      await WebNotification.requestPermission();
      WebNotification.show(
        "Waktunya Mencatat Keuangan! 💸",
        "Jangan biarkan pengeluaran Anda hari ini terlewat. Catat sekarang di Kuskas!",
      );
    }

    if (mounted) {
      _showInAppReminderDialog();
    }
  }

  void _showInAppReminderDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xE60E132D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.15),
                      border: Border.all(
                        color: AppColors.primaryLight.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: AppColors.primaryLight,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Waktunya Mencatat Keuangan! 💸',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Jangan biarkan pengeluaran Anda hari ini terlewat. Catat sekarang di Kuskas agar keuangan Anda tetap terpantau dengan baik!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Nanti Saja'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              VoiceFab.showVoiceSheet(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Catat Sekarang',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedGlowingBackground(
        child: Stack(
          children: [
            // Screen Content
            Positioned.fill(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
            
            // Custom Floating Glass Navigation Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0x260F1532), // Translucent Navy
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, 'Home'),
                        _buildNavItem(1, Icons.receipt_long_rounded, 'Riwayat'),
                        
                        // Center Glowing Voice FAB
                        GestureDetector(
                          onTap: () => VoiceFab.showVoiceSheet(context),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: AppColors.primaryGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        
                        _buildNavItem(2, Icons.pie_chart_rounded, 'Statistik'),
                        _buildNavItem(3, Icons.article_rounded, 'Berita'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => MainNavigation.selectedIndexNotifier.value = index,
          splashColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primary.withOpacity(0.15) 
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  color: isSelected ? AppColors.primaryLight : AppColors.textHint, 
                  size: 26,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textHint,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
