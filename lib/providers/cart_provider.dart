import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import 'product_provider.dart';

class CartState {
  final List<CartItemModel> items;
  final double discountValue;
  final String discountType; // 'nominal' | 'persen'
  final String discountInput;

  const CartState({
    this.items = const [],
    this.discountValue = 0,
    this.discountType = 'nominal',
    this.discountInput = '',
  });

  double get subtotal =>
      items.fold(0, (acc, item) => acc + item.subtotal);

  double get computedDiscount {
    final val = double.tryParse(discountInput) ?? 0;
    if (discountType == 'persen') {
      return (subtotal * val / 100).clamp(0, subtotal);
    }
    return val.clamp(0, subtotal);
  }

  double get total => subtotal - computedDiscount;

  int get itemCount => items.fold(0, (acc, item) => acc + item.quantity);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItemModel>? items,
    double? discountValue,
    String? discountType,
    String? discountInput,
  }) {
    return CartState(
      items: items ?? this.items,
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
      discountInput: discountInput ?? this.discountInput,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addProduct(ProductModel product) {
    final current = state.items;
    final idx = current.indexWhere((i) => i.product.id == product.id);

    if (idx >= 0) {
      final updated = List<CartItemModel>.from(current);
      updated[idx] = updated[idx].copyWith(
        quantity: updated[idx].quantity + 1,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...current, CartItemModel(product: product, quantity: 1)],
      );
    }

    ref.read(productsProvider.notifier).decrementStockLocally(product.id, 1);
  }

  void removeItem(String productId) {
    final item = state.items.firstWhere((i) => i.product.id == productId);
    ref
        .read(productsProvider.notifier)
        .incrementStockLocally(productId, item.quantity);
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void updateQuantity(String productId, int newQty) {
    if (newQty <= 0) {
      removeItem(productId);
      return;
    }

    final idx = state.items.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;

    final diff = newQty - state.items[idx].quantity;
    if (diff > 0) {
      ref
          .read(productsProvider.notifier)
          .decrementStockLocally(productId, diff);
    } else if (diff < 0) {
      ref
          .read(productsProvider.notifier)
          .incrementStockLocally(productId, diff.abs());
    }

    final updated = List<CartItemModel>.from(state.items);
    updated[idx] = updated[idx].copyWith(quantity: newQty);
    state = state.copyWith(items: updated);
  }

  void setDiscount({String? input, String? type}) {
    state = state.copyWith(
      discountInput: input ?? state.discountInput,
      discountType: type ?? state.discountType,
    );
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
