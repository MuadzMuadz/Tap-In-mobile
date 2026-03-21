import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/transaction_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/toast.dart';

class CheckoutSheet extends ConsumerStatefulWidget {
  const CheckoutSheet({super.key});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  String _paymentMethod = 'cash';
  bool _loading = false;
  bool _success = false;

  Future<void> _processCheckout() async {
    final user = ref.read(currentUserProvider);
    final cart = ref.read(cartProvider);
    if (user == null || cart.isEmpty) return;

    setState(() => _loading = true);
    try {
      await TransactionService.createTransaction(
        userId: user.id,
        items: cart.items,
        total: cart.total,
        discount: cart.computedDiscount,
        paymentMethod: _paymentMethod,
      );

      ref.read(cartProvider.notifier).clear();
      await ref.read(productsProvider.notifier).refresh();

      setState(() {
        _loading = false;
        _success = true;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        showToast(context, 'Transaksi gagal. Coba lagi.', ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _success
                  ? _buildSuccessView(context)
                  : _buildCheckoutView(context, cart, profile, controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutView(
    BuildContext context,
    CartState cart,
    dynamic profile,
    ScrollController controller,
  ) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        Text('Pembayaran', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),

        // Order summary
        _Section(
          title: 'Ringkasan Pesanan',
          child: Column(
            children: [
              ...cart.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.product.name} x${item.quantity}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 16),
              if (cart.computedDiscount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Diskon',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    Text(
                      '- ${CurrencyFormatter.format(cart.computedDiscount)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  Text(
                    CurrencyFormatter.format(cart.total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Payment method
        _Section(
          title: 'Metode Pembayaran',
          child: Row(
            children: [
              Expanded(
                child: _PaymentOption(
                  icon: Icons.payments_rounded,
                  label: 'Tunai',
                  selected: _paymentMethod == 'cash',
                  onTap: () => setState(() => _paymentMethod = 'cash'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PaymentOption(
                  icon: Icons.qr_code_rounded,
                  label: 'QRIS',
                  selected: _paymentMethod == 'qris',
                  onTap: () => setState(() => _paymentMethod = 'qris'),
                ),
              ),
            ],
          ),
        ),

        // QRIS display
        if (_paymentMethod == 'qris') ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Scan QRIS',
            child: Center(
              child: profile?.qrisString != null
                  ? Column(
                      children: [
                        QrImageView(
                          data: profile!.qrisString!,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan QR di atas untuk membayar',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(Icons.qr_code_2_rounded,
                            size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
                        const Text(
                          'QRIS belum disetup.\nPergi ke Pengaturan untuk upload QRIS.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textTertiary, fontSize: 13),
                        ),
                      ],
                    ),
            ),
          ),
        ],

        const SizedBox(height: 28),

        AppButton(
          label: 'Konfirmasi Pembayaran',
          loading: _loading,
          onPressed: _processCheckout,
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.successSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 44),
          ),
          const SizedBox(height: 20),
          Text('Transaksi Berhasil!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Terima kasih, pembayaran telah diterima.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Kembali ke Kasir'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textTertiary,
                size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
