import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/tap_in_logo.dart';
import '../../widgets/product_card.dart';
import '../../widgets/cart_panel.dart';
import '../../widgets/toast.dart';
import '../products/product_form_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';
import 'checkout_sheet.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _activeCategory = AppStrings.allCategories;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  bool _cartVisible = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> _getCategories(List<ProductModel> products) {
    final cats = products
        .map((p) => p.category)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return [AppStrings.allCategories, ...cats];
  }

  List<ProductModel> _filteredProducts(List<ProductModel> products) {
    return products.where((p) {
      final matchCat = _activeCategory == AppStrings.allCategories ||
          p.category == _activeCategory;
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  void _addToCart(ProductModel product) {
    // Check stock
    if (product.trackStock && (product.stock ?? 0) <= 0) {
      showToast(context, '${product.name} stok habis', ToastType.warning);
      return;
    }
    ref.read(cartProvider.notifier).addProduct(product);
    showToast(context, '${product.name} masuk keranjang', ToastType.success);
  }

  void _openCart() => setState(() => _cartVisible = true);
  void _closeCart() => setState(() => _cartVisible = false);

  void _openCheckout() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CheckoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final isTablet = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, profile?.storeName),
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Gagal memuat produk',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.refresh(productsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (products) {
          final categories = _getCategories(products);
          final filtered = _filteredProducts(products);

          if (isTablet) {
            // Tablet: side-by-side layout
            return Row(
              children: [
                Expanded(
                  child: _buildProductPanel(
                      context, categories, filtered, products),
                ),
                Container(
                  width: 360,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                        left: BorderSide(color: AppColors.borderLight)),
                  ),
                  child: CartPanel(
                    onCheckout: _openCheckout,
                  ),
                ),
              ],
            );
          }

          // Phone: stack layout
          return Stack(
            children: [
              _buildProductPanel(context, categories, filtered, products),
              // Cart FAB
              if (!cart.isEmpty)
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: _CartFab(
                    cart: cart,
                    onTap: _openCart,
                  ),
                ),
              // Cart bottom sheet (inline)
              if (_cartVisible)
                _CartOverlay(
                  onClose: _closeCart,
                  onCheckout: () {
                    _closeCart();
                    _openCheckout();
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String? storeName) {
    return AppBar(
      title: Row(
        children: [
          const TapInLogo(),
          const SizedBox(width: 10),
          if (storeName != null && storeName.isNotEmpty)
            Text(
              storeName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.dashboard_rounded, size: 20),
          color: AppColors.primary,
          tooltip: 'Dashboard',
          onPressed: () => _openPage(context, const DashboardScreen()),
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded, size: 20),
          color: AppColors.textSecondary,
          tooltip: 'Pengaturan',
          onPressed: () => _openPage(context, const SettingsScreen()),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 20),
          color: AppColors.error,
          tooltip: 'Keluar',
          onPressed: () async {
            final confirm = await _confirmLogout(context);
            if (confirm == true && mounted) {
              await ref.read(authNotifierProvider.notifier).signOut();
            }
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildProductPanel(
    BuildContext context,
    List<String> categories,
    List<ProductModel> filtered,
    List<ProductModel> all,
  ) {
    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: AppStrings.searchProduct,
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textTertiary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),

        // Category tabs + Add button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = categories[i];
                        final active = cat == _activeCategory;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _activeCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: active
                                    ? Colors.white
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _openProductForm(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tambah'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Product count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '${filtered.length} produk${_searchQuery.isNotEmpty ? ' untuk "$_searchQuery"' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),

        // Product grid
        if (filtered.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.inventory_2_outlined,
                    size: 56,
                    color: AppColors.textTertiary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Produk "$_searchQuery" tidak ditemukan'
                        : _activeCategory != AppStrings.allCategories
                            ? 'Tidak ada produk di kategori "$_activeCategory"'
                            : AppStrings.noProducts,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (_searchQuery.isEmpty && _activeCategory == AppStrings.allCategories) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openProductForm(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Tambah Produk'),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final p = filtered[i];
                return ProductCard(
                  product: p,
                  onAdd: () => _addToCart(p),
                  onEdit: () => _openProductForm(context, product: p),
                  onDelete: () => _confirmDeleteProduct(context, p),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openProductForm(BuildContext context, {ProductModel? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(initialData: product),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(
      BuildContext context, ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin hapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(productsProvider.notifier).deleteProduct(product);
      ref.read(cartProvider.notifier).removeItem(product.id);
      if (mounted) showToast(context, AppStrings.productDeleted, ToastType.info);
    }
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

// ── Cart FAB ─────────────────────────────────────────────────
class _CartFab extends StatelessWidget {
  final CartState cart;
  final VoidCallback onTap;

  const _CartFab({required this.cart, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_cart_rounded,
                      color: Colors.white, size: 20),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'KERANJANG',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0xFF94A3B8),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(cart.total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF94A3B8), size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Cart Overlay (mobile) ────────────────────────────────────
class _CartOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onCheckout;

  const _CartOverlay({required this.onClose, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withOpacity(0.4),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'Keranjang',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: CartPanel(onCheckout: onCheckout, isMobile: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
