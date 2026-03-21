import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/profile_model.dart';
import 'supabase_service.dart';

class ProfileService {
  ProfileService._();

  static const _table = 'profiles';

  static Future<ProfileModel?> fetchProfile(String userId) async {
    try {
      final data = await SupabaseService.client
          .from(_table)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      final profile = ProfileModel.fromJson(data as Map<String, dynamic>);

      // Resolve signed QRIS URL
      if (profile.qrisUrl != null) {
        final signed = await SupabaseService.getQrisSignedUrl(profile.qrisUrl!);
        if (signed != null) return profile.copyWith(qrisUrl: signed);
      }

      return profile;
    } catch (_) {
      return null;
    }
  }

  static Future<ProfileModel> upsertProfile({
    required String userId,
    String? storeName,
    String? qrisString,
    File? qrisImageFile,
    String? existingQrisUrl,
  }) async {
    String? qrisUrl = existingQrisUrl;

    if (qrisImageFile != null) {
      if (existingQrisUrl != null) {
        try {
          await SupabaseService.deleteFile(
            SupabaseService.qrisBucket,
            existingQrisUrl,
          );
        } catch (_) {}
      }
      final ext = path.extension(qrisImageFile.path).replaceFirst('.', '');
      final filename = '${userId}_${const Uuid().v4()}.$ext';
      final bytes = await qrisImageFile.readAsBytes();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      qrisUrl = await SupabaseService.uploadFile(
        SupabaseService.qrisBucket,
        filename,
        bytes,
        mime,
      );
    }

    final payload = {
      'id': userId,
      'store_name': storeName?.trim(),
      'qris_url': qrisUrl,
      'qris_string': qrisString?.trim(),
    };

    final data = await SupabaseService.client
        .from(_table)
        .upsert(payload)
        .select()
        .single();

    return ProfileModel.fromJson(data as Map<String, dynamic>);
  }
}
