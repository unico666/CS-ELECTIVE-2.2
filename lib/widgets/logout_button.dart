import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../core/ui.dart';
import '../providers/cart_provider.dart';
import '../providers/service_providers.dart';

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Log out',
      icon: const Icon(Icons.logout),
      onPressed: () async {
        ref.read(cartProvider.notifier).clear();
        try {
          await ref.read(authServiceProvider).signOut();
        } catch (error) {
          if (context.mounted) showMessage(context, friendlyError(error));
        }
      },
    );
  }
}
