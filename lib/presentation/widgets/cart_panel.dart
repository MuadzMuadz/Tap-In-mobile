import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/cart_provider.dart';

class CartPanel extends ConsumerStatefulWidget {
  final VoidCallback onCheckout;
  final bool isMobile;

  const CartPanel({
    super.key,
    required this.onCheckout,
    this.isMobile = false,
  });

  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  final _discountCtrl = TextEditingController();
  String _discountType = 'nominal';

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isMobile) ...[
            Row(
              children: [
                const Icon(Icons.shopping_cart_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Keranjang',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Items list
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 48,
                            color: AppColors.textTertiary.withOpacity(0.3)),
                        const SizedBox(height: 8),
                        const Text(
                          'Keranjang masih kosong',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 16),
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return _CartItem(
                        name: item.product.name,
                        price: item.product.price,
                        quantity: item.quantity,
                        subtotal: item.subtotal,
                        onRemove: () => ref
                            .read(cartProvider.notifier)
                            .removeItem(item.product.id),
                        onDecrement: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.product.id, item.quantity - 1),
                        onIncrement: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.product.id, item.quantity + 1),
                      );
                    },
                  ),
          ),

          if (!cart.isEmpty) ...[
            const Divider(height: 24),

            // Discount
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diskon',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (v) {
                          ref
                              .read(cartProvider.notifier)
                              .setDiscount(input: v);
                        },
                        decoration: const InputDecoration(
                          hintText: '0',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ToggleChip(
                      label: 'Rp',
                      active: _discountType == 'nominal',
                      onTap: () {
                        setState(() => _discountType = 'nominal');
                        ref
                            .read(cartProvider.notifier)
                            .setDiscount(type: 'nominal');
                      },
                    ),
                    const SizedBox(width: 6),
                    _ToggleChip(
                      label: '%',
                      active: _discountType == 'persen',
                      onTap: () {
                        setState(() => _discountType = 'persen');
                        ref
                            .read(cartProvider.notifier)
                            .setDiscount(type: 'persen');
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary
            _SummaryRow(
              label: 'Subtotal',
              value: CurrencyFormatter.format(cart.subtotal),
            ),
            if (cart.computedDiscount > 0) ...[
              const SizedBox(height: 4),
              _SummaryRow(
                label: 'Diskon',
                value: '- ${CurrencyFormatter.format(cart.computedDiscount)}',
                valueColor: AppColors.error,
              ),
            ],
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Total',
              value: CurrencyFormatter.format(cart.total),
              large: true,
            ),

            const SizedBox(height: 16),

            // Checkout button
            FilledButton.icon(
              onPressed: widget.onCheckout,
              icon: const Icon(Icons.payment_rounded, size: 18),
              label: const Text('Bayar Sekarang'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                CurrencyFormatter.format(price),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _QtyBtn(
              icon: quantity == 1
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              color: quantity == 1 ? AppColors.error : AppColors.textSecondary,
              onTap: quantity == 1 ? onRemove : onDecrement,
            ),
            SizedBox(
              width: 28,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            _QtyBtn(
                icon: Icons.add_rounded,
                color: AppColors.primary,
                onTap: onIncrement),
          ],
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            CurrencyFormatter.format(subtotal),
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool large;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.large = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: large ? 15 : 13,
            fontWeight: large ? FontWeight.w800 : FontWeight.w500,
            color: large ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 18 : 13,
            fontWeight: FontWeight.w900,
            color: valueColor ?? (large ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
