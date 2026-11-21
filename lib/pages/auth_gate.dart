import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../providers/auth_providers.dart';
import '../providers/service_providers.dart';
import '../widgets/state_views.dart';
import 'admin_home.dart';
import 'customer_home.dart';
import 'login_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, _) => Scaffold(
        body: ErrorView(
          message: friendlyError(error),
          onRetry: () => ref.invalidate(authStateProvider),
        ),
      ),
      data: (state) {
        if (state.session == null) return const LoginPage();

        final profile = ref.watch(profileProvider);
        return profile.when(
          loading: () => const Scaffold(body: LoadingView()),
          error: (error, _) => Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  tooltip: 'Log out',
                  icon: const Icon(Icons.logout),
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            ),
            body: ErrorView(
              message: friendlyError(error),
              permissionDenied: isPermissionDenied(error),
              onRetry: () => ref.invalidate(profileProvider),
            ),
          ),
          data: (value) {
            if (value == null) return const LoginPage();
            return value.isAdmin ? const AdminHome() : const CustomerHome();
          },
        );
      },
    );
  }
}
