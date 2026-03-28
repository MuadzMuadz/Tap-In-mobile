import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/tap_in_logo.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/toast.dart';

enum _AuthView { login, register, forgot }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _AuthView _view = _AuthView.login;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty) {
      showToast(context, 'Email tidak boleh kosong', ToastType.error);
      return;
    }

    setState(() => _loading = true);

    try {
      final notifier = ref.read(authNotifierProvider.notifier);

      switch (_view) {
        case _AuthView.login:
          await notifier.signIn(email, password);
        case _AuthView.register:
          if (password.length < 6) {
            showToast(context, 'Password minimal 6 karakter', ToastType.error);
            setState(() => _loading = false);
            return;
          }
          await notifier.signUp(email, password);
          if (mounted) {
            showToast(
              context,
              'Pendaftaran berhasil! Cek email untuk konfirmasi.',
              ToastType.success,
            );
            setState(() => _view = _AuthView.login);
          }
        case _AuthView.forgot:
          await notifier.resetPassword(email);
          if (mounted) {
            showToast(
              context,
              'Link reset kata sandi dikirim ke email kamu.',
              ToastType.success,
            );
            setState(() => _view = _AuthView.login);
          }
      }

      final authState = ref.read(authNotifierProvider);
      if (authState.hasError && mounted) {
        showToast(context, _errorMessage(authState.error), ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        showToast(context, _errorMessage(e), ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMessage(Object? error) {
    final msg = error?.toString() ?? '';
    if (msg.contains('Invalid login credentials')) {
      return 'Email atau kata sandi salah';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Konfirmasi email kamu terlebih dahulu';
    }
    if (msg.contains('User already registered')) {
      return 'Email sudah terdaftar';
    }
    if (msg.contains('SocketException') || msg.contains('Failed host lookup') || msg.contains('Network')) {
      return 'Tidak ada koneksi internet. Periksa jaringan kamu.';
    }
    if (msg.contains('AuthException') || msg.contains('AuthApiException')) {
      return 'Autentikasi gagal: $msg';
    }
    return 'Terjadi kesalahan: $msg';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 420 : double.infinity),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const TapInLogo(large: true),
                const SizedBox(height: 40),

                // Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _view == _AuthView.login
                            ? 'Masuk ke akun kamu'
                            : _view == _AuthView.register
                                ? 'Buat akun baru'
                                : 'Reset kata sandi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),

                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'nama@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                      ),

                      if (_view != _AuthView.forgot) ...[
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _passwordCtrl,
                          label: 'Kata Sandi',
                          hint: '••••••••',
                          obscureText: _obscure,
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textTertiary,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ],

                      if (_view == _AuthView.login) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _view = _AuthView.forgot),
                            child: const Text('Lupa kata sandi?'),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      AppButton(
                        label: _view == _AuthView.login
                            ? 'Masuk'
                            : _view == _AuthView.register
                                ? 'Daftar'
                                : 'Kirim Link Reset',
                        onPressed: _loading ? null : _submit,
                        loading: _loading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Toggle view
                if (_view == _AuthView.login)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Belum punya akun?',
                          style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        onPressed: () =>
                            setState(() => _view = _AuthView.register),
                        child: const Text('Daftar sekarang'),
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() => _view = _AuthView.login),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Kembali ke login'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
