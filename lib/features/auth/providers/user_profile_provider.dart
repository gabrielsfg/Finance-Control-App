import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/models/user_profile.dart';
import 'auth_provider.dart';

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final authState = await ref.watch(authNotifierProvider.future);
    if (!authState.isAuthenticated) return null;
    return ref.read(authRepositoryProvider).getProfile();
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
        UserProfileNotifier.new);
