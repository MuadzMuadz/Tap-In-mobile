import '../models/cart_item_model.dart';
import '../models/transaction_model.dart';
import 'supabase_service.dart';

class TransactionService {
  TransactionService._();

  static const _table = 'transactions';

  static Future<TransactionModel> createTransaction({
    required String userId,
    required List<CartItemModel> items,
    required double total,
    required double discount,
    required String paymentMethod,
  }) async {
    final txItems = items
        .map((i) => TransactionItemModel(
              productId: i.product.id,
              productName: i.product.name,
              price: i.product.price,
              quantity: i.quantity,
              subtotal: i.subtotal,
            ))
        .toList();

    final payload = {
      'user_id': userId,
      'total': total,
      'discount': discount,
      'payment_method': paymentMethod,
      'items': txItems.map((e) => e.toJson()).toList(),
    };

    final data = await SupabaseService.client
        .from(_table)
        .insert(payload)
        .select()
        .single();

    // Update stock for tracked products
    for (final item in items) {
      if (item.product.trackStock) {
        try {
          await SupabaseService.client.from('products').rpc('decrement_stock', params: {
            'product_id': item.product.id,
            'qty': item.quantity,
          });
        } catch (_) {
          // Fallback: direct update
          final current = item.product.stock ?? 0;
          await SupabaseService.client
              .from('products')
              .update({'stock': (current - item.quantity).clamp(0, 999999)})
              .eq('id', item.product.id);
        }
      }
    }

    return TransactionModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<TransactionModel>> fetchTransactions({
    required String userId,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    var query = SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    if (from != null) {
      query = query.gte('created_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('created_at', to.toIso8601String());
    }

    final data = await query;
    return (data as List)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Map<String, double>> fetchRevenueSummary(String userId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);

    Future<double> sum(DateTime from) async {
      final data = await SupabaseService.client
          .from(_table)
          .select('total')
          .eq('user_id', userId)
          .gte('created_at', from.toIso8601String());

      return (data as List).fold<double>(
        0,
        (acc, e) => acc + ((e as Map)['total'] as num).toDouble(),
      );
    }

    final results = await Future.wait([
      sum(todayStart),
      sum(weekStart),
      sum(monthStart),
    ]);

    return {
      'today': results[0],
      'week': results[1],
      'month': results[2],
    };
  }
}
