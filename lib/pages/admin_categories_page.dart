import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../core/ui.dart';
import '../models/category.dart';
import '../providers/product_providers.dart';
import '../widgets/state_views.dart';

Future<void> showCategoryDialog(BuildContext context, {Category? category}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _CategoryDialog(initialName: category?.name ?? ''),
  );
  if (name == null || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  try {
    final actions = container.read(categoryActionsProvider);
    if (category == null) {
      await actions.create(name);
    } else {
      await actions.rename(category.id, name);
    }
  } catch (error) {
    if (context.mounted) showMessage(context, friendlyError(error));
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.initialName});

  final String initialName;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName.isNotEmpty;
    return AlertDialog(
      title: Text(isEdit ? 'Edit category' : 'Add category'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Category name'),
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Name is required' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AdminCategoriesPage extends ConsumerWidget {
  const AdminCategoriesPage({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "${category.name}"? Products in it will become uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(categoryActionsProvider).delete(category.id);
    } catch (error) {
      if (context.mounted) showMessage(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return AsyncValueView<List<Category>>(
      value: categories,
      onRetry: () => ref.invalidate(categoriesProvider),
      emptyMessage: 'No categories yet. Tap + to add one.',
      emptyIcon: Icons.category_outlined,
      builder: (list) => ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: list.length,
        itemBuilder: (_, index) {
          final category = list[index];
          return ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(category.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showCategoryDialog(context, category: category),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  onPressed: () => _confirmDelete(context, ref, category),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
