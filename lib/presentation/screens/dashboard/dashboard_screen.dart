import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/transaction_service.dart';
import '../../../providers/auth_provider.dart';

enum _Period { today, week, month, year, custom }

final _periodProvider = StateProvider.autoDispose<_Period>((_) => _Period.today);
final _customFromProvider = StateProvider.autoDispose<DateTime?>((_) => null);
final _customToProvider = StateProvider.autoDispose<DateTime?>((_) => null);

final _transactionsProvider = FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final period = ref.watch(_periodProvider);
  final now = DateTime.now();

  DateTime? from;
  DateTime? to;

  switch (period) {
    case _Period.today:
      from = DateTime(now.year, now.month, now.day);
    case _Period.week:
      from = now.subtract(Duration(days: now.weekday - 1));
      from = DateTime(from.year, from.month, from.day);
    case _Period.month:
      from = DateTime(now.year, now.month);
    case _Period.year:
      from = DateTime(now.year);
    case _Period.custom:
      from = ref.watch(_customFromProvider);
      to = ref.watch(_customToProvider);
      if (to != null) {
        to = DateTime(to.year, to.month, to.day, 23, 59, 59);
      }
  }

  return TransactionService.fetchTransactions(
    userId: user.id,
    from: from,
    to: to,
    limit: 200,
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);
    final txAsync = ref.watch(_transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_transactionsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _PeriodChip(label: 'Hari Ini', period: _Period.today, selected: period),
                _PeriodChip(label: 'Minggu Ini', period: _Period.week, selected: period),
                _PeriodChip(label: 'Bulan Ini', period: _Period.month, selected: period),
                _PeriodChip(label: 'Tahun Ini', period: _Period.year, selected: period),
                _CustomDateChip(selected: period),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: txAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Gagal memuat: $e')),
              data: (transactions) => _DashboardContent(transactions: transactions),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends ConsumerWidget {
  final String label;
  final _Period period;
  final _Period selected;

  const _PeriodChip({required this.label, required this.period, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = selected == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => ref.read(_periodProvider.notifier).state = period,
        selectedColor: AppColors.primarySurface,
        checkmarkColor: AppColors.primary,
      ),
    );
  }
}

class _CustomDateChip extends ConsumerWidget {
  final _Period selected;
  const _CustomDateChip({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = selected == _Period.custom;
    final from = ref.watch(_customFromProvider);
    final to = ref.watch(_customToProvider);
    final fmt = DateFormat('d MMM', 'id_ID');

    String label = 'Kustom';
    if (isSelected && from != null) {
      label = to != null
          ? '${fmt.format(from)} - ${fmt.format(to)}'
          : 'Dari ${fmt.format(from)}';
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      avatar: isSelected ? null : const Icon(Icons.date_range_rounded, size: 16),
      onSelected: (_) async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: from != null && to != null
              ? DateTimeRange(start: from, end: to)
              : null,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (range != null) {
          ref.read(_customFromProvider.notifier).state = range.start;
          ref.read(_customToProvider.notifier).state = range.end;
          ref.read(_periodProvider.notifier).state = _Period.custom;
        }
      },
      selectedColor: AppColors.primarySurface,
      checkmarkColor: AppColors.primary,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _DashboardContent({required this.transactions});

  double get _totalRevenue =>
      transactions.fold(0, (sum, tx) => sum + tx.total);
  int get _orderCount => transactions.length;
  double get _avgOrderValue =>
      _orderCount > 0 ? _totalRevenue / _orderCount : 0;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Pendapatan',
                  value: CurrencyFormatter.compact(_totalRevenue),
                  icon: Icons.attach_money_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'Transaksi',
                  value: _orderCount.toString(),
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'Rata-rata',
                  value: CurrencyFormatter.compact(_avgOrderValue),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.info,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text('Riwayat Transaksi',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          if (transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 56, color: AppColors.textTertiary.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    const Text('Belum ada transaksi di periode ini',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            ...transactions.map((tx) => _TransactionTile(transaction: tx)),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
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

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
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
                  Text('${transaction.items.length} item',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                      fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isQris ? AppColors.primarySurface : AppColors.successSurface,
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
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Transaksi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(fmt.format(transaction.createdAt.toLocal()),
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const Divider(height: 20),
            ...transaction.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('${item.productName} x${item.quantity}',
                              style: const TextStyle(fontSize: 13))),
                      Text(CurrencyFormatter.format(item.subtotal),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
            const Divider(height: 20),
            if (transaction.discount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Diskon',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Text('-${CurrencyFormatter.format(transaction.discount)}',
                      style: const TextStyle(color: AppColors.error)),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(CurrencyFormatter.format(transaction.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
