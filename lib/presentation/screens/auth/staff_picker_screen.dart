import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/staff_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/staff_provider.dart';
import '../../widgets/tap_in_logo.dart';
import '../../widgets/toast.dart';

class StaffPickerScreen extends ConsumerStatefulWidget {
  const StaffPickerScreen({super.key});

  @override
  ConsumerState<StaffPickerScreen> createState() => _StaffPickerScreenState();
}

class _StaffPickerScreenState extends ConsumerState<StaffPickerScreen> {
  StaffModel? _selected;
  String _pin = '';
  bool _loading = false;

  void _selectStaff(StaffModel staff) {
    setState(() {
      _selected = staff;
      _pin = '';
    });
  }

  void _onPinKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _onPinDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    final staff = _selected;
    if (staff == null) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    if (_pin == staff.pin) {
      ref.read(activeStaffProvider.notifier).state = staff;
    } else {
      showToast(context, 'PIN salah, coba lagi', ToastType.error);
      setState(() {
        _pin = '';
        _loading = false;
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TapInLogo(),
                  TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Keluar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _selected == null
                  ? _buildStaffList(staffAsync)
                  : _buildPinPad(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList(AsyncValue<List<StaffModel>> staffAsync) {
    return staffAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Gagal memuat: $e')),
      data: (staffList) {
        if (staffList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off_rounded, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text('Belum ada kasir',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('Tambahkan kasir di menu Pengaturan',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Siapa yang bertugas?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisExtent: 100,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: staffList.length,
                itemBuilder: (context, i) {
                  final staff = staffList[i];
                  return _StaffCard(staff: staff, onTap: () => _selectStaff(staff));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPinPad() {
    final staff = _selected!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Back button
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: () => setState(() {
                _selected = null;
                _pin = '';
              }),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Ganti kasir'),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Avatar
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(staff.name, style: Theme.of(context).textTheme.titleMedium),
        if (staff.isOwner)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Pemilik',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 32),

        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < _pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: filled ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),

        // Numpad
        if (_loading)
          const CircularProgressIndicator(color: AppColors.primary)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              children: [
                for (final row in [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['', '0', '⌫'],
                ])
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row.map((key) {
                      if (key.isEmpty) return const SizedBox(width: 80, height: 60);
                      return _PinKey(
                        label: key,
                        onTap: () {
                          if (key == '⌫') {
                            _onPinDelete();
                          } else {
                            _onPinKey(key);
                          }
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onTap;

  const _StaffCard({required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              staff.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (staff.isOwner)
              Text(
                'Pemilik',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PinKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 60,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
