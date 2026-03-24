import '../models/staff_model.dart';
import 'supabase_service.dart';

class StaffService {
  StaffService._();

  static const _table = 'staff';

  static Future<List<StaffModel>> fetchStaff(String userId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('is_owner', ascending: false)
        .order('name');
    return (data as List)
        .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<StaffModel> createStaff({
    required String userId,
    required String name,
    required String pin,
    bool isOwner = false,
  }) async {
    final data = await SupabaseService.client
        .from(_table)
        .insert({
          'user_id': userId,
          'name': name,
          'pin': pin,
          'is_owner': isOwner,
        })
        .select()
        .single();
    return StaffModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> updateStaff({
    required String id,
    String? name,
    String? pin,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (pin != null) payload['pin'] = pin;
    if (payload.isEmpty) return;

    await SupabaseService.client.from(_table).update(payload).eq('id', id);
  }

  static Future<void> deleteStaff(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }

  /// Ensure owner entry exists for a user (called on first login)
  static Future<StaffModel> ensureOwner({
    required String userId,
    required String name,
  }) async {
    final existing = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_owner', true)
        .maybeSingle();

    if (existing != null) {
      return StaffModel.fromJson(existing as Map<String, dynamic>);
    }

    return createStaff(
      userId: userId,
      name: name,
      pin: '0000',
      isOwner: true,
    );
  }
}
