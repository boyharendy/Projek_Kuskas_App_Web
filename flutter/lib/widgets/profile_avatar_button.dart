import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';

class ProfileAvatarButton extends StatefulWidget {
  const ProfileAvatarButton({super.key});

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          await Navigator.pushNamed(context, '/profile');
          if (mounted) {
            setState(() {});
          }
        },
        child: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final user = Supabase.instance.client.auth.currentUser;
            final displayName = user?.userMetadata?['full_name'] ?? 
                                user?.userMetadata?['display_name'] ?? 
                                'Kuskas User';
            final avatarMeta = user?.userMetadata?['avatar_index'];
            final avatarIndex = avatarMeta is int 
                ? avatarMeta 
                : int.tryParse(avatarMeta?.toString() ?? '0') ?? 0;
            final avatarBase64 = user?.userMetadata?['avatar_base64'] as String?;

            final List<Color> gradientColors;
            if (avatarIndex == 0) {
              gradientColors = AppColors.primaryGradient;
            } else if (avatarIndex == 1) {
              gradientColors = AppColors.accentGradient;
            } else if (avatarIndex == 2) {
              gradientColors = AppColors.secondaryGradient;
            } else if (avatarIndex == 3) {
              gradientColors = [AppColors.income, Colors.tealAccent];
            } else {
              gradientColors = AppColors.primaryGradient;
            }

            final ImageProvider? avatarImage = (avatarIndex == -1 && avatarBase64 != null)
                ? MemoryImage(base64Decode(avatarBase64))
                : null;

            return Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF0F1532),
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'K',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      );
  }
}

