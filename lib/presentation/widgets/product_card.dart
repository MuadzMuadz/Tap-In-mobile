import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _outOfStock =>
      product.trackStock && (product.stock ?? 0) <= 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _outOfStock ? null : onAdd,
      child: Opacity(
        opacity: _outOfStock ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: _buildImage(),
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                    if (product.trackStock) ...[
                      const SizedBox(height: 2),
                      Text(
                        _outOfStock ? 'Stok habis' : 'Stok: ${product.stock}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _outOfStock
                              ? AppColors.error
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    _IconBtn(
                        icon: Icons.edit_rounded,
                        color: AppColors.textTertiary,
                        onTap: onEdit),
                    _IconBtn(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.error,
                        onTap: onDelete),
                    const Spacer(),
                    GestureDetector(
                      onTap: _outOfStock ? null : onAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _outOfStock
                              ? AppColors.surfaceVariant
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color:
                              _outOfStock ? AppColors.textTertiary : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (product.signedImageUrl != null) {
      return CachedNetworkImage(
        imageUrl: product.signedImageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.image_outlined,
            size: 32, color: AppColors.textTertiary),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
