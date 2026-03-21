import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/toast.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final ProductModel? initialData;

  const ProductFormScreen({super.key, this.initialData});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  bool _trackStock = false;
  bool _loading = false;
  File? _imageFile;
  String? _imagePreviewUrl;

  bool get _isEditing => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    if (d != null) {
      _nameCtrl.text = d.name;
      _priceCtrl.text = d.price.toStringAsFixed(0);
      _categoryCtrl.text = d.category ?? '';
      _trackStock = d.trackStock;
      _stockCtrl.text = d.stock?.toString() ?? '';
      _imagePreviewUrl = d.signedImageUrl ?? d.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imagePreviewUrl = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', ''));
    final category = _categoryCtrl.text.trim();
    final stock = _trackStock && _stockCtrl.text.isNotEmpty
        ? int.tryParse(_stockCtrl.text)
        : null;

    if (price == null || price <= 0) {
      showToast(context, 'Harga harus lebih dari 0', ToastType.error);
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isEditing) {
        await ref.read(productsProvider.notifier).updateProduct(
              id: widget.initialData!.id,
              name: name,
              price: price,
              category: category.isEmpty ? null : category,
              trackStock: _trackStock,
              stock: stock,
              imageFile: _imageFile,
              existingImageUrl: widget.initialData!.imageUrl,
            );
      } else {
        await ref.read(productsProvider.notifier).addProduct(
              name: name,
              price: price,
              category: category.isEmpty ? null : category,
              trackStock: _trackStock,
              stock: stock,
              imageFile: _imageFile,
            );
      }

      if (mounted) {
        showToast(context, 'Produk berhasil disimpan', ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Gagal menyimpan produk. Coba lagi.', ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.borderLight,
                    style: BorderStyle.solid,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildImagePreview(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Name
            AppTextField(
              controller: _nameCtrl,
              label: 'Nama Produk',
              hint: 'Contoh: Nasi Goreng',
              prefixIcon: Icons.label_outline_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Nama produk tidak boleh kosong';
                }
                if (v.trim().length > 100) return 'Maksimal 100 karakter';
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Price
            AppTextField(
              controller: _priceCtrl,
              label: 'Harga (Rp)',
              hint: '0',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money_rounded,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Harga harus lebih dari 0';
                if (n > 1000000000) return 'Harga terlalu besar';
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Category
            AppTextField(
              controller: _categoryCtrl,
              label: 'Kategori (opsional)',
              hint: 'Contoh: Makanan, Minuman',
              prefixIcon: Icons.category_outlined,
            ),

            const SizedBox(height: 20),

            // Track stock toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lacak Stok',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('Aktifkan untuk memantau jumlah stok produk',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _trackStock,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _trackStock = v),
                  ),
                ],
              ),
            ),

            if (_trackStock) ...[
              const SizedBox(height: 14),
              AppTextField(
                controller: _stockCtrl,
                label: 'Jumlah Stok',
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_rounded,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],

            const SizedBox(height: 32),

            AppButton(
              label: _isEditing ? 'Simpan Perubahan' : 'Tambah Produk',
              loading: _loading,
              onPressed: _submit,
              width: double.infinity,
              icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_imageFile!, fit: BoxFit.cover),
          Positioned(
            bottom: 8,
            right: 8,
            child: _EditOverlay(),
          ),
        ],
      );
    }

    if (_imagePreviewUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(_imagePreviewUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _emptyImage()),
          Positioned(
            bottom: 8,
            right: 8,
            child: _EditOverlay(),
          ),
        ],
      );
    }

    return _emptyImage();
  }

  Widget _emptyImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 36, color: AppColors.textTertiary.withOpacity(0.5)),
        const SizedBox(height: 8),
        const Text(
          'Tap untuk upload foto produk',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EditOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text('Ganti Foto',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
