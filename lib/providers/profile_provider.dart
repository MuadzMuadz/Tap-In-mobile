import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/profile_model.dart';
import '../data/services/profile_service.dart';
import 'auth_provider.dart';

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return ProfileService.fetchProfile(user.id);
  }

  Future<void> save({
    String? storeName,
    String? qrisString,
    File? qrisImageFile,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final current = state.valueOrNull;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ProfileService.upsertProfile(
          userId: user.id,
          storeName: storeName,
          qrisString: qrisString,
          qrisImageFile: qrisImageFile,
          existingQrisUrl: current?.qrisUrl,
        ));
  }
}
