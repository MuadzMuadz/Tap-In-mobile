import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/transaction_service.dart';
import '../../../providers/auth_provider.dart';

final _revenueSummaryProvider = FutureProvider.autoDispose<Map<String, double>>(
  (ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return {};
    return TransactionService.fetchRevenueSummary(user.id);
  },
);

final _transactionsProvider =
    FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return TransactionService.fetchTransactions(userId: user.id, limit: 30);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(_revenueSummaryProvider);
    final transactions = ref.watch(_transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(_revenueSummaryProvider);
          ref.invalidate(_transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Revenue cards
            summary.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              )),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) => _RevenueCards(summary: data),
            ),

            const SizedBox(height: 20),

            Text('Riwayat Transaksi',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            transactions.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Text('Gagal memuat transaksi',
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 56,
                              color: AppColors.textTertiary.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text('Belum ada transaksi',
                              style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: data
                      .map((tx) => _TransactionTile(transaction: tx))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueCards extends StatelessWidget {
  final Map<String, double> summary;

  const _RevenueCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RevenueCard(
          icon: Icons.today_rounded,
          label: 'Hari Ini',
          amount: summary['today'] ?? 0,
          color: AppColors.primary,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RevenueCard(
                icon: Icons.date_range_rounded,
                label: 'Minggu Ini',
                amount: summary['week'] ?? 0,
                color: AppColors.info,
                compact: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RevenueCard(
                icon: Icons.calendar_month_rounded,
                label: 'Bulan Ini',
                amount: summary['month'] ?? 0,
                color: AppColors.success,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final bool compact;

  const _RevenueCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: compact ? 18 : 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.compact(amount),
                  style: TextStyle(
                    fontSize: compact ? 15 : 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final isQris = transaction.paymentMethod == 'qris';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isQris ? Icons.qr_code_rounded : Icons.payments_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.items.length} item',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  fmt.format(transaction.createdAt.toLocal()),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(transaction.total),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isQris
                      ? AppColors.primarySurface
                      : AppColors.successSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isQris ? 'QRIS' : 'Tunai',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isQris ? AppColors.primary : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
