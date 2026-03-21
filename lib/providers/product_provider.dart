import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';
import '../data/services/product_service.dart';
import 'auth_provider.dart';

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<ProductModel>>(
  ProductsNotifier.new,
);

class ProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ProductService.fetchProducts(user.id);
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ProductService.fetchProducts(user.id),
    );
  }

  Future<void> addProduct({
    required String name,
    required double price,
    String? category,
    bool trackStock = false,
    int? stock,
    File? imageFile,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final product = await ProductService.createProduct(
      userId: user.id,
      name: name,
      price: price,
      category: category,
      trackStock: trackStock,
      stock: stock,
      imageFile: imageFile,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData([product, ...current]);

    // Re-fetch to get signed URL
    await refresh();
  }

  Future<void> updateProduct({
    required String id,
    required String name,
    required double price,
    String? category,
    bool trackStock = false,
    int? stock,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ProductService.updateProduct(
      id: id,
      userId: user.id,
      name: name,
      price: price,
      category: category,
      trackStock: trackStock,
      stock: stock,
      imageFile: imageFile,
      existingImageUrl: existingImageUrl,
    );

    await refresh();
  }

  Future<void> deleteProduct(ProductModel product) async {
    await ProductService.deleteProduct(product);
    state = AsyncData(
      (state.valueOrNull ?? []).where((p) => p.id != product.id).toList(),
    );
  }

  void decrementStockLocally(String productId, int qty) {
    final products = state.valueOrNull;
    if (products == null) return;
    state = AsyncData(products.map((p) {
      if (p.id == productId && p.trackStock && p.stock != null) {
        return p.copyWith(stock: (p.stock! - qty).clamp(0, 999999));
      }
      return p;
    }).toList());
  }

  void incrementStockLocally(String productId, int qty) {
    final products = state.valueOrNull;
    if (products == null) return;
    state = AsyncData(products.map((p) {
      if (p.id == productId && p.trackStock && p.stock != null) {
        return p.copyWith(stock: p.stock! + qty);
      }
      return p;
    }).toList());
  }
}
