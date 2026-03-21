import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import 'supabase_service.dart';

class ProductService {
  ProductService._();

  static const _table = 'products';

  static Future<List<ProductModel>> fetchProducts(String userId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final products = (data as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Enrich with signed URLs
    final enriched = await Future.wait(
      products.map((p) async {
        if (p.imageUrl != null) {
          final signed = await SupabaseService.getProductSignedUrl(p.imageUrl!);
          if (signed != null) return p.copyWith(signedImageUrl: signed);
        }
        return p;
      }),
    );

    return enriched;
  }

  static Future<ProductModel> createProduct({
    required String userId,
    required String name,
    required double price,
    String? category,
    bool trackStock = false,
    int? stock,
    File? imageFile,
  }) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(userId, imageFile);
    }

    final data = await SupabaseService.client
        .from(_table)
        .insert({
          'user_id': userId,
          'name': name.trim(),
          'price': price,
          'category': category?.trim().isEmpty == true ? null : category?.trim(),
          'track_stock': trackStock,
          'stock': trackStock ? stock : null,
          'image_url': imageUrl,
        })
        .select()
        .single();

    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<ProductModel> updateProduct({
    required String id,
    required String userId,
    required String name,
    required double price,
    String? category,
    bool trackStock = false,
    int? stock,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    String? imageUrl = existingImageUrl;

    if (imageFile != null) {
      // Delete old image
      if (existingImageUrl != null) {
        try {
          await SupabaseService.deleteFile(
            SupabaseService.productBucket,
            existingImageUrl,
          );
        } catch (_) {}
      }
      imageUrl = await _uploadImage(userId, imageFile);
    }

    final data = await SupabaseService.client
        .from(_table)
        .update({
          'name': name.trim(),
          'price': price,
          'category': category?.trim().isEmpty == true ? null : category?.trim(),
          'track_stock': trackStock,
          'stock': trackStock ? stock : null,
          'image_url': imageUrl,
        })
        .eq('id', id)
        .select()
        .single();

    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteProduct(ProductModel product) async {
    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('id', product.id);

    if (product.imageUrl != null) {
      try {
        await SupabaseService.deleteFile(
          SupabaseService.productBucket,
          product.imageUrl!,
        );
      } catch (_) {}
    }
  }

  static Future<void> decrementStock(String productId, int qty) async {
    await SupabaseService.client.rpc('decrement_stock', params: {
      'product_id': productId,
      'qty': qty,
    });
  }

  static Future<String> _uploadImage(String userId, File file) async {
    final ext = path.extension(file.path).replaceFirst('.', '');
    final filename = '${userId}_${const Uuid().v4()}.$ext';
    final bytes = await file.readAsBytes();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return SupabaseService.uploadFile(
      SupabaseService.productBucket,
      filename,
      bytes,
      mime,
    );
  }
}
