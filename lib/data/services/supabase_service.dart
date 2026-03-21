import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;

  static const _bucketProduct = 'bucket-product';
  static const _bucketQris = 'bucket-qris';

  // Cache signed URLs to avoid excessive requests
  static final Map<String, ({String url, DateTime expiresAt})> _urlCache = {};

  static Future<String?> getSignedUrl(String bucket, String path) async {
    final key = '$bucket/$path';
    final cached = _urlCache[key];
    final now = DateTime.now();

    if (cached != null && cached.expiresAt.isAfter(now.add(const Duration(minutes: 1)))) {
      return cached.url;
    }

    try {
      final url = await client.storage
          .from(bucket)
          .createSignedUrl(path, 3600);
      _urlCache[key] = (url: url, expiresAt: now.add(const Duration(hours: 1)));
      return url;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getProductSignedUrl(String imageUrl) async {
    final path = _extractPath(imageUrl, _bucketProduct);
    if (path == null) return null;
    return getSignedUrl(_bucketProduct, path);
  }

  static Future<String?> getQrisSignedUrl(String qrisUrl) async {
    final path = _extractPath(qrisUrl, _bucketQris);
    if (path == null) return null;
    return getSignedUrl(_bucketQris, path);
  }

  static String? _extractPath(String url, String bucket) {
    if (url.contains('/public/')) {
      final parts = url.split('/public/$bucket/');
      if (parts.length > 1) {
        return parts[1].split('?')[0];
      }
    }
    return url;
  }

  static Future<String> uploadFile(String bucket, String path, List<int> bytes, String mimeType) async {
    await client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  static Future<void> deleteFile(String bucket, String path) async {
    final cleanPath = _extractPath(path, bucket) ?? path;
    await client.storage.from(bucket).remove([cleanPath]);
    _urlCache.remove('$bucket/$cleanPath');
  }

  static String get productBucket => _bucketProduct;
  static String get qrisBucket => _bucketQris;
}
