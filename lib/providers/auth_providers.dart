import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_profile.dart';
import 'service_providers.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authChanges;
});

final userIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.session?.user.id;
});

final profileProvider = FutureProvider<AppProfile?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  return ref.watch(authServiceProvider).fetchProfile(userId);
});
