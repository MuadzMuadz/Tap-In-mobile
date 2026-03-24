import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/supabase_service.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/toast.dart';

class StockOpnameScreen extends ConsumerStatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  ConsumerState<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends ConsumerState<StockOpnameScreen> {
  final Map<String, int> _counts = {};
  bool _saving = false;

  int _getCount(ProductModel p) => _counts[p.id] ?? (p.stock ?? 0);
  bool _hasVariance(ProductModel p) => _getCount(p) != (p.stock ?? 0);

  Future<void> _save(List<ProductModel> tracked) async {
    setState(() => _saving = true);
    try {
      await Future.wait(
        tracked.map((p) async {
          final count = _getCount(p);
          if (count != (p.stock ?? 0)) {
            await SupabaseService.client
                .from('products')
                .update({'stock': count})
                .eq('id', p.id);
          }
        }),
      );
      ref.invalidate(productsProvider);
      if (mounted) {
        showToast(context, 'Stok opname berhasil disimpan', ToastType.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showToast(context, 'Gagal menyimpan: $e', ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Stok Opname'), centerTitle: false),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Gagal memuat produk: $e')),
        data: (products) {
          final tracked = products.where((p) => p.trackStock).toList();

          if (tracked.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('Tidak ada produk yang dilacak stoknya',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Aktifkan pelacakan stok di form produk',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            );
          }

          final variances = tracked.where(_hasVariance).toList();

          return Column(
            children: [
              if (variances.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.warning.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${variances.length} produk ada selisih stok',
                        style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tracked.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _OpnameRow(
                    product: tracked[i],
                    count: _getCount(tracked[i]),
                    onChanged: (val) => setState(() => _counts[tracked[i].id] = val),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    onPressed: _saving ? null : () => _save(tracked),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan Stok Opname'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OpnameRow extends StatefulWidget {
  final ProductModel product;
  final int count;
  final ValueChanged<int> onChanged;

  const _OpnameRow({required this.product, required this.count, required this.onChanged});

  @override
  State<_OpnameRow> createState() => _OpnameRowState();
}

class _OpnameRowState extends State<_OpnameRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.count.toString());
  }

  @override
  void didUpdateWidget(_OpnameRow old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) _ctrl.text = widget.count.toString();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _systemStock => widget.product.stock ?? 0;
  int get _variance => widget.count - _systemStock;
  bool get _hasVariance => _variance != 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _hasVariance
            ? (_variance > 0
                ? AppColors.success.withOpacity(0.05)
                : AppColors.error.withOpacity(0.05))
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasVariance
              ? (_variance > 0 ? AppColors.success : AppColors.error).withOpacity(0.3)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.product.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Sistem: $_systemStock',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textTertiary)),
                if (_hasVariance)
                  Text(
                    'Selisih: ${_variance > 0 ? '+' : ''}$_variance',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _variance > 0 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              _CountBtn(
                icon: Icons.remove_rounded,
                onTap: widget.count > 0
                    ? () {
                        final v = widget.count - 1;
                        widget.onChanged(v);
                        _ctrl.text = v.toString();
                      }
                    : null,
              ),
              SizedBox(
                width: 56,
                child: TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n >= 0) widget.onChanged(n);
                  },
                ),
              ),
              _CountBtn(
                icon: Icons.add_rounded,
                onTap: () {
                  final v = widget.count + 1;
                  widget.onChanged(v);
                  _ctrl.text = v.toString();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        backgroundColor:
            onTap != null ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        foregroundColor: onTap != null ? AppColors.primary : AppColors.textTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(6),
        minimumSize: const Size(32, 32),
      ),
    );
  }
}
