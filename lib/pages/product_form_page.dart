import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/errors.dart';
import '../core/ui.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/product_providers.dart';
import '../widgets/state_views.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  final _picker = ImagePicker();
  int? _categoryId;
  XFile? _image;
  Uint8List? _preview;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _price = TextEditingController(text: product == null ? '' : product.price.toString());
    _stock = TextEditingController(text: product == null ? '' : product.stock.toString());
    _categoryId = product?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _image = file;
        _preview = bytes;
      });
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(productActionsProvider).save(
            id: widget.product?.id,
            image: _image,
            data: {
              'name': _name.text.trim(),
              'description': _description.text.trim(),
              'price': double.parse(_price.text.trim()),
              'stock': int.parse(_stock.text.trim()),
              'category_id': _categoryId,
            },
          );
      if (!mounted) return;
      showMessage(context, _isEdit ? 'Product updated' : 'Product added');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _imagePreview(ColorScheme scheme) {
    final existing = widget.product?.imageUrl;
    Widget child;
    if (_preview != null) {
      child = Image.memory(_preview!, fit: BoxFit.cover);
    } else if (existing != null) {
      child = Image.network(
        existing,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 48),
      );
    } else {
      child = Icon(Icons.image_outlined, size: 48, color: scheme.outline);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: SizedBox.expand(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _imagePreview(scheme),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_image == null ? 'Choose image' : 'Change image'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price', prefixText: '₱ '),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null) return 'Price must be a number';
                    if (parsed < 0) return 'Price cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock quantity'),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null) return 'Stock must be a whole number';
                    if (parsed < 0) return 'Stock cannot be negative';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                categories.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: LoadingView(),
                  ),
                  error: (error, _) => ErrorView(
                    message: friendlyError(error),
                    permissionDenied: isPermissionDenied(error),
                    onRetry: () => ref.invalidate(categoriesProvider),
                  ),
                  data: (List<Category> list) => DropdownButtonFormField<int>(
                    initialValue: list.any((c) => c.id == _categoryId) ? _categoryId : null,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final category in list)
                        DropdownMenuItem(value: category.id, child: Text(category.name)),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) => value == null ? 'Choose a category' : null,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Add product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
