import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/staff_model.dart';
import '../data/services/staff_service.dart';
import 'auth_provider.dart';

/// Currently active staff member for this session
final activeStaffProvider = StateProvider<StaffModel?>((ref) => null);

/// List of all staff for the current user
final staffListProvider = FutureProvider<List<StaffModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return StaffService.fetchStaff(user.id);
});

/// Notifier for staff CRUD operations
class StaffNotifier extends AsyncNotifier<List<StaffModel>> {
  @override
  Future<List<StaffModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return StaffService.fetchStaff(user.id);
  }

  Future<void> add({required String name, required String pin, bool isOwner = false}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await StaffService.createStaff(
      userId: user.id,
      name: name,
      pin: pin,
      isOwner: isOwner,
    );
    ref.invalidateSelf();
  }

  Future<void> update({required String id, String? name, String? pin}) async {
    await StaffService.updateStaff(id: id, name: name, pin: pin);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await StaffService.deleteStaff(id);
    ref.invalidateSelf();
  }
}

final staffNotifierProvider =
    AsyncNotifierProvider<StaffNotifier, List<StaffModel>>(StaffNotifier.new);
