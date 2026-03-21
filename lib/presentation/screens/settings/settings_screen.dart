import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/qris_validator.dart';
import '../../../providers/profile_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/toast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _storeNameCtrl = TextEditingController();
  final _qrisStringCtrl = TextEditingController();
  bool _loading = false;
  File? _qrisImageFile;
  bool? _qrisStringValid;
  bool _initialized = false;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _qrisStringCtrl.dispose();
    super.dispose();
  }

  void _init(profile) {
    if (_initialized) return;
    _initialized = true;
    _storeNameCtrl.text = profile?.storeName ?? '';
    _qrisStringCtrl.text = profile?.qrisString ?? '';
    if (profile?.qrisString != null) {
      _qrisStringValid = QrisValidator.validate(profile!.qrisString!);
    }
  }

  Future<void> _pickQrisImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _qrisImageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_qrisStringCtrl.text.isNotEmpty &&
        _qrisStringValid == false) {
      showToast(context, 'QRIS string tidak valid', ToastType.error);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(profileProvider.notifier).save(
            storeName: _storeNameCtrl.text.trim(),
            qrisString: _qrisStringCtrl.text.trim().isEmpty
                ? null
                : _qrisStringCtrl.text.trim(),
            qrisImageFile: _qrisImageFile,
          );
      if (mounted) {
        showToast(context, 'Pengaturan berhasil disimpan', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Gagal menyimpan. Coba lagi.', ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('Gagal memuat pengaturan')),
        data: (profile) {
          _init(profile);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Store info section
              _SectionCard(
                title: 'Informasi Toko',
                icon: Icons.store_rounded,
                child: AppTextField(
                  controller: _storeNameCtrl,
                  label: 'Nama Toko',
                  hint: 'Contoh: Warung Bu Sari',
                  prefixIcon: Icons.storefront_outlined,
                ),
              ),

              const SizedBox(height: 16),

              // QRIS section
              _SectionCard(
                title: 'Setup QRIS',
                icon: Icons.qr_code_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QRIS image
                    const Text('Gambar QRIS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickQrisImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildQrisPreview(profile?.qrisUrl),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // QRIS string
                    AppTextField(
                      controller: _qrisStringCtrl,
                      label: 'QRIS String (EMV)',
                      hint: '000201...',
                      maxLines: 3,
                      onChanged: (v) {
                        setState(() {
                          _qrisStringValid = v.isEmpty
                              ? null
                              : QrisValidator.validate(v);
                        });
                      },
                      suffixIcon: _qrisStringValid != null
                          ? Icon(
                              _qrisStringValid!
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: _qrisStringValid!
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            )
                          : null,
                    ),

                    if (_qrisStringValid == false) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'QRIS string tidak valid. Pastikan format EMV QR Code benar.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else if (_qrisStringValid == true) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'QRIS string valid!',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              AppButton(
                label: 'Simpan Pengaturan',
                loading: _loading,
                onPressed: _save,
                width: double.infinity,
                icon: Icons.save_rounded,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQrisPreview(String? url) {
    if (_qrisImageFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_qrisImageFile!, fit: BoxFit.contain),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Ganti',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }

    if (url != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(url, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _emptyQris()),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Ganti',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      );
    }

    return _emptyQris();
  }

  Widget _emptyQris() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 32, color: AppColors.textTertiary.withOpacity(0.5)),
        const SizedBox(height: 8),
        const Text(
          'Upload gambar QRIS kamu',
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
