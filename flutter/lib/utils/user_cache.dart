import 'dart:convert' show base64Decode;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserCache {
  static String? displayName;
  static int avatarIndex = 0;
  static String? avatarBase64;
  
  static final ValueNotifier<int> updateNotifier = ValueNotifier<int>(0);

  static void notifyUpdate() {
    updateNotifier.value++;
  }

  static Future<void> loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      displayName = null;
      avatarIndex = 0;
      avatarBase64 = null;
      notifyUpdate();
      return;
    }

    // 1. Initial quick load from auth metadata
    displayName = user.userMetadata?['full_name'] ?? user.userMetadata?['display_name'];
    final avatarMeta = user.userMetadata?['avatar_index'];
    avatarIndex = avatarMeta is int 
        ? avatarMeta 
        : int.tryParse(avatarMeta?.toString() ?? '0') ?? 0;
    avatarBase64 = user.userMetadata?['avatar_base64'];
    notifyUpdate();

    // 2. Fetch from database public.users for up-to-date and non-bloated data
    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userData != null) {
        final dbFullName = userData['full_name'] as String?;
        final dbAvatarUrl = userData['avatar_url'] as String?;

        if (dbFullName != null && dbFullName.isNotEmpty) {
          displayName = dbFullName;
        }

        if (dbAvatarUrl != null) {
          final parsedIndex = int.tryParse(dbAvatarUrl);
          if (parsedIndex != null) {
            avatarIndex = parsedIndex;
            avatarBase64 = null;
          } else {
            avatarIndex = -1;
            avatarBase64 = dbAvatarUrl; // holds the base64 string
          }
        }
        notifyUpdate();
      }
    } catch (e) {
      debugPrint('Error loading user profile in cache: $e');
    }

    // 3. Clear auth user metadata avatar_base64 to avoid oversized token / Cloudflare 400 Bad Request
    if (user.userMetadata?['avatar_base64'] != null) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'avatar_base64': null, // clean it up
            },
          ),
        );
        debugPrint('Successfully cleaned up avatar_base64 from auth user_metadata inside UserCache');
      } catch (e) {
        debugPrint('Error cleaning up auth userMetadata: $e');
      }
    }
  }
}
