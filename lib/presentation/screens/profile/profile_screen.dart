import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/toast.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordCtrl.text;
    final newPass = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      showToast(context, 'Semua field harus diisi', ToastType.error);
      return;
    }
    if (newPass.length < 6) {
      showToast(context, 'Password baru minimal 6 karakter', ToastType.error);
      return;
    }
    if (newPass != confirm) {
      showToast(context, 'Konfirmasi password tidak cocok', ToastType.error);
      return;
    }

    setState(() => _loading = true);
    try {
      // Re-authenticate with current password
      final user = ref.read(currentUserProvider);
      if (user?.email == null) throw Exception('User tidak ditemukan');

      await SupabaseService.auth.signInWithPassword(
        email: user!.email!,
        password: current,
      );

      // Update password
      await SupabaseService.auth.updateUser(
        UserAttributes(password: newPass),
      );

      if (mounted) {
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        showToast(context, 'Password berhasil diubah', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('Invalid login credentials')
            ? 'Password saat ini salah'
            : 'Gagal mengubah password. Coba lagi.';
        showToast(context, msg, ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Akun'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    (profile?.storeName?.isNotEmpty == true
                            ? profile!.storeName![0]
                            : user?.email?[0] ?? '?')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile?.storeName?.isNotEmpty == true)
                        Text(
                          profile!.storeName!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      Text(
                        user?.email ?? '-',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text('Ubah Password',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Verifikasi dengan password saat ini sebelum mengubah',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: _currentPasswordCtrl,
            label: 'Password Saat Ini',
            hint: '••••••••',
            obscureText: _obscureCurrent,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
          const SizedBox(height: 14),

          AppTextField(
            controller: _newPasswordCtrl,
            label: 'Password Baru',
            hint: 'Minimal 6 karakter',
            obscureText: _obscureNew,
            prefixIcon: Icons.lock_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 14),

          AppTextField(
            controller: _confirmPasswordCtrl,
            label: 'Konfirmasi Password Baru',
            hint: '••••••••',
            obscureText: _obscureConfirm,
            prefixIcon: Icons.lock_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 24),

          AppButton(
            label: 'Ubah Password',
            loading: _loading,
            onPressed: _loading ? null : _changePassword,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
