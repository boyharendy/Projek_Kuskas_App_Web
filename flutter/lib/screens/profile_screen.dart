import 'dart:convert' show base64Encode, base64Decode, jsonDecode, jsonEncode;
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_code_dart_decoder/qr_code_dart_decoder.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../services/notification_listener_service.dart';
import '../utils/web_notification.dart';
import '../widgets/animated_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  bool _isListenerEnabled = false;
  final NotificationListenerService _listenerService = NotificationListenerService();

  // Profile fields
  String _displayName = 'Kuskas User';
  String _email = 'user@kuskas.app';
  bool _isAnonymous = true;
  int _selectedAvatarIndex = 0;
  String? _avatarBase64;

  // App settings fields
  bool _isDailyAlertsEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _loadUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  void _loadUserProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _displayName = user.userMetadata?['full_name'] ?? user.userMetadata?['display_name'] ?? 'Kuskas User';
        _email = user.email ?? 'user@kuskas.app';
        _isAnonymous = user.email == null || user.email!.isEmpty;
        
        final avatarMeta = user.userMetadata?['avatar_index'];
        _selectedAvatarIndex = avatarMeta is int 
            ? avatarMeta 
            : int.tryParse(avatarMeta?.toString() ?? '0') ?? 0;
            
        _avatarBase64 = user.userMetadata?['avatar_base64'];

        // Load reminder settings
        _isDailyAlertsEnabled = user.userMetadata?['reminder_enabled'] as bool? ?? false;
        _reminderHour = user.userMetadata?['reminder_hour'] as int? ?? 20;
        _reminderMinute = user.userMetadata?['reminder_minute'] as int? ?? 0;
      });
    }
  }

  Future<void> _checkPermission() async {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    if (isAndroid) {
      final enabled = await _listenerService.checkPermission();
      if (mounted) {
        setState(() {
          _isListenerEnabled = enabled;
        });
      }
    }
  }

  Future<void> _handleToggleListener() async {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    if (!isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fitur deteksi transaksi dari notifikasi hanya didukung pada perangkat Android'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
      return;
    }

    await _listenerService.openSettings();
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _displayName);
    final emailController = TextEditingController(text: _email);
    int selectedAvatar = _selectedAvatarIndex;
    String? dialogAvatarBase64 = _avatarBase64;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xE60E132D), // 90% opacity surface
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Profil',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (!isSaving)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                                onPressed: () => Navigator.pop(context),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Avatar selection row
                        const Text(
                          'Pilih Avatar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ...List.generate(4, (index) {
                              final List<Color> gradientColors;
                              if (index == 0) {
                                gradientColors = AppColors.primaryGradient;
                              } else if (index == 1) {
                                gradientColors = AppColors.accentGradient;
                              } else if (index == 2) {
                                gradientColors = AppColors.secondaryGradient;
                              } else {
                                gradientColors = [AppColors.income, Colors.tealAccent];
                              }
                              
                              final isSelected = selectedAvatar == index;
                              
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedAvatar = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 2.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: gradientColors[0].withOpacity(0.5),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (dialogAvatarBase64 != null)
                              GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    selectedAvatar = -1;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedAvatar == -1 ? Colors.white : Colors.transparent,
                                      width: 2.0,
                                    ),
                                    boxShadow: selectedAvatar == -1
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.5),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF0F1532),
                                    backgroundImage: MemoryImage(base64Decode(dialogAvatarBase64!)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              try {
                                final image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (image != null && context.mounted) {
                                  final bytes = await image.readAsBytes();
                                  if (context.mounted) {
                                    final base64Result = await _showCropDialog(context, bytes);
                                    if (base64Result != null) {
                                      setDialogState(() {
                                        dialogAvatarBase64 = base64Result;
                                        selectedAvatar = -1; // Select custom avatar
                                      });
                                    }
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal memilih gambar: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.add_a_photo_rounded, size: 16, color: AppColors.primaryLight),
                            label: Text(
                              dialogAvatarBase64 != null ? 'Ganti Foto Kustom' : 'Unggah Foto Kustom',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Nama Lengkap',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama lengkap',
                            fillColor: const Color(0x1F0F1532),
                            filled: true,
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textHint),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          enabled: !_isAnonymous,
                          style: TextStyle(
                            color: _isAnonymous ? AppColors.textHint : Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'user@kuskas.app',
                            fillColor: const Color(0x1F0F1532),
                            filled: true,
                            prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textHint),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            helperText: _isAnonymous
                                ? 'Email tidak dapat diubah dalam Mode Demo'
                                : null,
                            helperStyle: const TextStyle(color: AppColors.textHint, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
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
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (nameController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Nama tidak boleh kosong'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                        return;
                                      }
                                      
                                      setDialogState(() {
                                        isSaving = true;
                                      });
                                      
                                      try {
                                        final user = Supabase.instance.client.auth.currentUser;
                                        if (user != null) {
                                          await Supabase.instance.client.auth.updateUser(
                                            UserAttributes(
                                              data: {
                                                'full_name': nameController.text.trim().isEmpty ? 'Kuskas User' : nameController.text.trim(),
                                                'display_name': nameController.text.trim().isEmpty ? 'Kuskas User' : nameController.text.trim(),
                                                'avatar_index': selectedAvatar,
                                                'avatar_base64': selectedAvatar == -1 ? dialogAvatarBase64 : null,
                                              },
                                            ),
                                          );

                                          // Also update public.users table for web dashboard integration
                                          await Supabase.instance.client.from('users').upsert({
                                            'id': user.id,
                                            'email': user.email ?? 'anon-${user.id.substring(0, 8)}@kuskas.app',
                                            'full_name': nameController.text.trim().isEmpty ? 'Kuskas User' : nameController.text.trim(),
                                            'avatar_url': selectedAvatar.toString(),
                                            'updated_at': DateTime.now().toUtc().toIso8601String(),
                                          });
                                        }
                                        
                                        if (mounted) {
                                          setState(() {
                                            _displayName = nameController.text.trim();
                                            _selectedAvatarIndex = selectedAvatar;
                                            _avatarBase64 = selectedAvatar == -1 ? dialogAvatarBase64 : null;
                                          });
                                          
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Profil berhasil diperbarui'),
                                                backgroundColor: AppColors.success,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            );
                                            Navigator.pop(context);
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Gagal memperbarui profil: $e'),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      } finally {
                                        setDialogState(() {
                                          isSaving = false;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Perubahan',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showCropDialog(BuildContext context, Uint8List rawBytes) async {
    final GlobalKey repaintKey = GlobalKey();
    bool isProcessing = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setCropState) {
            return BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      const Row(
                        children: [
                          Icon(Icons.crop_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sesuaikan Foto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Geser dan cubit (zoom) untuk menyesuaikan bagian foto yang ingin disorot.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Circular cropping viewport with RepaintBoundary and viewfinder grid
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RepaintBoundary(
                              key: repaintKey,
                              child: Container(
                                width: 240,
                                height: 240,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0F1532),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InteractiveViewer(
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  boundaryMargin: const EdgeInsets.all(120.0), // Allows panning corners into center
                                  child: Image.memory(
                                    rawBytes,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // Viewfinder grid overlay (outside RepaintBoundary to avoid capturing it)
                            IgnorePointer(
                              child: Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const CustomPaint(
                                  painter: CropGridPainter(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Batal'),
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
                              ),
                              child: ElevatedButton(
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        setCropState(() {
                                          isProcessing = true;
                                        });
                                        
                                        try {
                                          // Capture visual viewport of RepaintBoundary
                                          final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                                          
                                          // Give a small delay to make sure UI is settled
                                          await Future.delayed(const Duration(milliseconds: 100));
                                          
                                          final image = await boundary.toImage(pixelRatio: 2.5); // 240 * 2.5 = 600px
                                          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                                          
                                          if (byteData != null) {
                                            final croppedBytes = byteData.buffer.asUint8List();
                                            final base64Str = base64Encode(croppedBytes);
                                            
                                            if (context.mounted) {
                                              Navigator.pop(context, base64Str);
                                            }
                                          } else {
                                            throw Exception('Gagal memproses data gambar');
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Gagal memotong gambar: $e'),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                          }
                                          setCropState(() {
                                            isProcessing = false;
                                          });
                                        }
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
                                child: isProcessing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Terapkan',
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
      },
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xE60E132D),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pengaturan Aplikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Notification switch and Time Picker inside one glassy container
                    _buildSettingSectionTitle('NOTIFIKASI HARIAN'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0x1F0F1532),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pengingat Harian',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Ingatkan untuk mencatat keuangan',
                                    style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isDailyAlertsEnabled,
                                activeThumbColor: AppColors.primaryLight,
                                activeTrackColor: AppColors.primary.withOpacity(0.35),
                                inactiveThumbColor: AppColors.textHint,
                                inactiveTrackColor: Colors.white.withOpacity(0.05),
                                onChanged: (val) async {
                                  setSheetState(() {
                                    _isDailyAlertsEnabled = val;
                                  });
                                  setState(() {
                                    _isDailyAlertsEnabled = val;
                                  });
                                  await _saveReminderSettings(val, _reminderHour, _reminderMinute);
                                },
                              ),
                            ],
                          ),
                          if (_isDailyAlertsEnabled) ...[
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white12, height: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Waktu Pengingat',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: const ColorScheme.dark(
                                              primary: AppColors.primary,
                                              onPrimary: Colors.white,
                                              surface: Color(0xFF0E132D),
                                              onSurface: Colors.white,
                                            ),
                                            dialogBackgroundColor: const Color(0xFF0E132D),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setSheetState(() {
                                        _reminderHour = picked.hour;
                                        _reminderMinute = picked.minute;
                                      });
                                      setState(() {
                                        _reminderHour = picked.hour;
                                        _reminderMinute = picked.minute;
                                      });
                                      await _saveReminderSettings(true, picked.hour, picked.minute);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.primaryLight.withOpacity(0.3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time_filled_rounded,
                                          color: AppColors.primaryLight,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Selesai Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.08),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveReminderSettings(bool enabled, int hour, int minute) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'reminder_enabled': enabled,
              'reminder_hour': hour,
              'reminder_minute': minute,
            },
          ),
        );
      }

      if (enabled && kIsWeb) {
        await WebNotification.requestPermission();
      }

      // Sync to native Android AlarmManager
      final isAndroid = !kIsWeb && Platform.isAndroid;
      if (isAndroid) {
        final platform = MethodChannel('com.example.kuskas/notification_listener');
        if (enabled) {
          await platform.invokeMethod('scheduleReminder', {
            'hour': hour,
            'minute': minute,
          });
        } else {
          await platform.invokeMethod('cancelReminder');
        }
      }

      final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      _showToast(enabled 
          ? 'Pengingat harian diset pukul $timeStr' 
          : 'Pengingat harian dinonaktifkan');
    } catch (e) {
      debugPrint('Gagal menyimpan pengingat: $e');
    }
  }

  void _showQRScanDialog() {
    final codeController = TextEditingController();
    bool isConnecting = false;
    String? loadingMessage;

    Future<String?> decodeQRFromBytes(Uint8List bytes) async {
      try {
        final decoder = QrCodeDartDecoder();
        final result = await decoder.decodeFile(bytes);
        return result?.text;
      } catch (e) {
        debugPrint('Error decoding QR: $e');
        return null;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            Future<void> processQRData(String rawData) async {
              String sessionId = rawData.trim();
              
              // Try parsing JSON if it contains JSON payload
              try {
                final Map<String, dynamic> data = jsonDecode(rawData);
                if (data.containsKey('session_id')) {
                  sessionId = data['session_id'].toString();
                }
              } catch (_) {
                // Treat as raw sessionId
              }

              // Validate UUID format
              final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
              if (!uuidRegex.hasMatch(sessionId)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Format QR Code tidak valid untuk login KUSKAS.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              setDialogState(() {
                isConnecting = true;
                loadingMessage = "Menghubungkan ke Web...";
              });

              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) throw Exception('Pengguna tidak masuk di aplikasi mobile');

                // Sync database user metadata name/email before login if possible
                final profileName = user.userMetadata?['full_name'] ?? 'Kuskas User';
                final profileEmail = user.email ?? 'anon-${user.id.substring(0, 8)}@kuskas.app';

                // Send POST request directly to local Laravel backend
                final uri = Uri.parse('http://localhost:8000/qr-login/authenticate');
                final response = await http.post(
                  uri,
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                  body: jsonEncode({
                    'session_id': sessionId,
                    'kuskas_user_id': user.id,
                    'name': profileName,
                    'email': profileEmail,
                  }),
                );

                if (response.statusCode != 200) {
                  Map<String, dynamic>? errorData;
                  try {
                    errorData = jsonDecode(response.body);
                  } catch (_) {}
                  throw Exception(errorData?['error'] ?? 'Gagal menghubungkan ke server web.');
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berhasil terhubung! Web Dashboard Anda akan login otomatis.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghubungkan: ${e.toString().replaceAll('Exception:', '').trim()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } finally {
                if (context.mounted) {
                  setDialogState(() {
                    isConnecting = false;
                    loadingMessage = null;
                  });
                }
              }
            }

            Future<void> pickAndDecode(ImageSource source) async {
              setDialogState(() {
                isConnecting = true;
                loadingMessage = source == ImageSource.camera ? "Membuka Kamera..." : "Membuka Galeri...";
              });

              try {
                final picker = ImagePicker();
                final image = await picker.pickImage(
                  source: source,
                  maxWidth: 1024,
                  maxHeight: 1024,
                );

                if (image != null) {
                  setDialogState(() {
                    loadingMessage = "Memproses QR Code...";
                  });

                  final bytes = await image.readAsBytes();
                  final qrText = await decodeQRFromBytes(bytes);

                  if (qrText != null && qrText.isNotEmpty) {
                    await processQRData(qrText);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(source == ImageSource.camera
                              ? 'Tidak terdeteksi QR Code dari kamera. Mohon dekatkan kamera ke QR Code di web.'
                              : 'Tidak terdeteksi QR Code pada gambar yang dipilih.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal membaca gambar: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } finally {
                if (context.mounted) {
                  setDialogState(() {
                    isConnecting = false;
                    loadingMessage = null;
                  });
                }
              }
            }

            return BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
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
                  child: isConnecting
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20),
                            const CircularProgressIndicator(
                              color: AppColors.primaryLight,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              loadingMessage ?? "Memproses...",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accentLight, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Hubungkan KUSKAS Web',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Gunakan kamera untuk memindai QR Code di layar browser web Anda, atau unggah gambar QR Code dari galeri.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Camera Scanning Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: AppColors.primaryGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => pickAndDecode(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                                    label: const Text(
                                      'Scan QR (Kamera)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Gallery Upload Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () => pickAndDecode(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library_rounded, color: AppColors.primaryLight),
                                  label: const Text(
                                    'Unggah dari Galeri',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              const Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white10)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'ATAU INPUT MANUAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textHint,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white10)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: codeController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan Session ID / QR data payload',
                                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
                                  fillColor: const Color(0x1F0F1532),
                                  filled: true,
                                  prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.textHint, size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
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
                                      child: const Text('Batal'),
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
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          final text = codeController.text.trim();
                                          if (text.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Kode input manual tidak boleh kosong.'),
                                                backgroundColor: AppColors.error,
                                              ),
                                            );
                                            return;
                                          }
                                          processQRData(text);
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
                                          'Hubungkan',
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
              ),
            );
          },
        );
      },
    );
  }

  void _showHelpCenterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xE60E132D),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.help_outline_rounded, color: Colors.amberAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Pusat Bantuan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildFAQTile(
                            question: 'Bagaimana cara mencatat transaksi baru?',
                            answer: 'Anda memiliki tiga opsi pencatatan:\n'
                                '1. Manual: Klik tombol "+" di dashboard dan isi formulir transaksi.\n'
                                '2. Suara (AI Voice): Tekan dan tahan tombol mikrofon di pojok kanan bawah, lalu ucapkan transaksi Anda (contoh: "beli kopi sore dua puluh ribu rupiah").\n'
                                '3. Otomatis: Aktifkan fitur Deteksi Transaksi Otomatis agar Kuskas secara otomatis menangkap pesan transaksi dari notifikasi e-wallet dan m-banking Anda.',
                          ),
                          _buildFAQTile(
                            question: 'Apa itu fitur Deteksi Transaksi Otomatis?',
                            answer: 'Fitur pintar ini memantau notifikasi yang masuk dari berbagai aplikasi keuangan (seperti Dana, OVO, GoPay, SeaBank, dan m-banking lainnya).\n\n'
                                'Jika ada transfer masuk atau keluar, Kuskas akan mendeteksi data tersebut dan menyimpannya di Notification Center (ikon lonceng kanan atas). Anda cukup mengklik lonceng tersebut untuk memvalidasi dan menyimpan transaksi secara instan tanpa perlu mengetik manual!',
                          ),
                          _buildFAQTile(
                            question: 'Bagaimana cara menggunakan fitur Catat Suara (AI)?',
                            answer: 'Gunakan tombol mikrofon melayang di pojok kanan bawah.\n\n'
                                'Tekan lama (hold) tombol tersebut, katakan transaksi Anda secara natural seperti: "makan siang padang 35 ribu", lalu lepaskan. AI Kuskas akan memproses ucapan Anda, memilah nominal, kategori (makanan/minuman), dan keterangan transaksi secara otomatis.',
                          ),
                          _buildFAQTile(
                            question: 'Bagaimana cara mengunduh laporan keuangan?',
                            answer: 'Masuk ke menu riwayat transaksi di dashboard, klik ikon ekspor di pojok kanan atas.\n\n'
                                'Kuskas mendukung ekspor data dalam format PDF yang rapi dengan visual grafik, serta format spreadsheet Excel (.xlsx) untuk kebutuhan analisis data yang lebih mendalam.',
                          ),
                          _buildFAQTile(
                            question: 'Apakah data saya aman?',
                            answer: 'Ya, seluruh data transaksi Anda disimpan secara aman menggunakan enkripsi standar industri di server cloud database .\n\n'
                                'Setiap pengguna hanya memiliki akses ke datanya masing-masing melalui kebijakan Row Level Security (RLS) yang ketat.',
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                                width: 1.0,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.support_agent_rounded, color: AppColors.primaryLight, size: 28),
                                SizedBox(height: 8),
                                Text(
                                  'Butuh Bantuan Lebih Lanjut?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Hubungi tim support kami melalui email support@kuskas.app untuk kendala teknis atau saran fitur.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFAQTile({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0x1F0F1532),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1.0,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primaryLight,
          collapsedIconColor: AppColors.textHint,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                answer,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.4),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF161B3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedGlowingBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Profil Saya',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                const SizedBox(height: 12),
                
                // 1. Premium Glassmorphic User Profile Card
                _buildUserProfileCard(),
                
                const SizedBox(height: 32),
                
                // 2. Menu Section Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'PENGATURAN & AKUN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                
                // 3. Glassmorphic Menu Items
                _buildMenuCard(
                  context,
                  icon: Icons.account_circle_outlined,
                  iconColor: AppColors.primaryLight,
                  title: 'Edit Profil',
                  onTap: _showEditProfileDialog,
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.notifications_active_outlined,
                  iconColor: AppColors.accentLight,
                  title: 'Deteksi Transaksi Otomatis',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isListenerEnabled ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          color: _isListenerEnabled ? AppColors.income : AppColors.textHint,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    ],
                  ),
                  onTap: _handleToggleListener,
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  iconColor: AppColors.accentLight,
                  title: 'Scan QR Login Web',
                  onTap: _showQRScanDialog,
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.settings_outlined,
                  iconColor: AppColors.secondaryLight,
                  title: 'Pengaturan Aplikasi',
                  onTap: _showSettingsSheet,
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.help_outline_rounded,
                  iconColor: Colors.amberAccent,
                  title: 'Pusat Bantuan',
                  onTap: _showHelpCenterSheet,
                ),
                
                const SizedBox(height: 16),
                
                _buildMenuCard(
                  context,
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  title: 'Keluar Akun',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileCard() {
    final List<Color> gradientColors;
    if (_selectedAvatarIndex == 0) {
      gradientColors = AppColors.primaryGradient;
    } else if (_selectedAvatarIndex == 1) {
      gradientColors = AppColors.accentGradient;
    } else if (_selectedAvatarIndex == 2) {
      gradientColors = AppColors.secondaryGradient;
    } else if (_selectedAvatarIndex == 3) {
      gradientColors = [AppColors.income, Colors.tealAccent];
    } else {
      gradientColors = AppColors.primaryGradient;
    }

    final ImageProvider? avatarImage = (_selectedAvatarIndex == -1 && _avatarBase64 != null)
        ? MemoryImage(base64Decode(_avatarBase64!))
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0x1F0F1532), // Translucent Navy
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.02),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar with glowing gradient borders
              Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF0F1532),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 18),
              
              // Name
              Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              
              // Email
              Text(
                _email,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              
              // Account Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppColors.income.withOpacity(0.25),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.income,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isAnonymous ? 'Mode Demo / Anonim' : 'Akun Terverifikasi',
                      style: const TextStyle(
                        color: AppColors.income,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    final itemColor = color ?? AppColors.textPrimary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x1F0F1532), // Translucent Navy
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1.0,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: itemColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
              ),
              trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
              onTap: onTap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ),
    );
  }
}

class CropGridPainter extends CustomPainter {
  const CropGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);

    // Draw vertical grid lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

