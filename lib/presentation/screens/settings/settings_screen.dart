import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/qris_validator.dart';
import '../../../data/models/staff_model.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/staff_provider.dart';
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

              const SizedBox(height: 16),

              // Staff management section
              _StaffSection(),

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

class _StaffSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffNotifierProvider);

    return _SectionCard(
      title: 'Manajemen Kasir',
      icon: Icons.people_alt_rounded,
      child: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Gagal memuat: $e'),
        data: (staffList) => Column(
          children: [
            ...staffList.map((s) => _StaffRow(staff: s)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showStaffDialog(context, ref),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Tambah Kasir'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStaffDialog(BuildContext context, WidgetRef ref, [StaffModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final pinCtrl = TextEditingController(text: existing?.pin ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tambah Kasir' : 'Edit Kasir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kasir'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              decoration: const InputDecoration(
                labelText: 'PIN (4 digit)',
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final pin = pinCtrl.text.trim();
              if (name.isEmpty || pin.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama dan PIN 4 digit wajib diisi')),
                );
                return;
              }
              Navigator.pop(ctx);
              if (existing == null) {
                await ref.read(staffNotifierProvider.notifier).add(name: name, pin: pin);
              } else {
                await ref.read(staffNotifierProvider.notifier).update(
                      id: existing.id,
                      name: name,
                      pin: pin,
                    );
              }
            },
            child: Text(existing == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }
}

class _StaffRow extends ConsumerWidget {
  final StaffModel staff;
  const _StaffRow({required this.staff});

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: staff.name);
    final pinCtrl = TextEditingController(text: staff.pin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Kasir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Kasir'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              decoration: const InputDecoration(
                  labelText: 'PIN (4 digit)', counterText: ''),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final pin = pinCtrl.text.trim();
              if (name.isEmpty || pin.length != 4) return;
              Navigator.pop(ctx);
              await ref.read(staffNotifierProvider.notifier).update(
                    id: staff.id,
                    name: name,
                    pin: pin,
                  );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primarySurface,
        child: Text(
          staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(staff.isOwner ? 'Pemilik' : 'Kasir',
          style: TextStyle(
            fontSize: 11,
            color: staff.isOwner ? AppColors.primary : AppColors.textTertiary,
          )),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            onPressed: () => _showEditDialog(context, ref),
            tooltip: 'Edit',
          ),
          if (!staff.isOwner)
            IconButton(
              icon: const Icon(Icons.delete_rounded, size: 18),
              color: AppColors.error,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Hapus Kasir?'),
                    content: Text('Hapus ${staff.name}?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal')),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(staffNotifierProvider.notifier).remove(staff.id);
                }
              },
              tooltip: 'Hapus',
            ),
        ],
      ),
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
