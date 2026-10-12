import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/net/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/product.dart';
import '../../widgets/common.dart';
import 'products_screen.dart' show productListProvider;

final _categoriesProvider =
    FutureProvider((ref) => ref.watch(productRepositoryProvider).categories());

final _brandsProvider =
    FutureProvider((ref) => ref.watch(productRepositoryProvider).brands());

final _productProvider = FutureProvider.family<Product, String>(
  (ref, id) => ref.watch(productRepositoryProvider).byId(id),
);

/// Create or edit one product, photos included.
///
/// Images go up through `POST Product/images` (multipart: `id`, repeated
/// `files`, optional `coverIndex`), which needs the product to exist — so on
/// create the product is saved first and the photos follow.
class ProductEditScreen extends ConsumerWidget {
  const ProductEditScreen({super.key, this.productId});

  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (productId == null) return const _ProductForm();

    return AsyncView(
      value: ref.watch(_productProvider(productId!)),
      onRetry: () => ref.invalidate(_productProvider(productId!)),
      loading: Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      data: (product) => _ProductForm(existing: product),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const _ProductForm({this.existing});

  final Product? existing;

  @override
  ConsumerState<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<_ProductForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _price = TextEditingController();
  final _salePrice = TextEditingController();
  final _shortDescription = TextEditingController();
  final _description = TextEditingController();
  final _initialStock = TextEditingController();

  final _newPhotos = <XFile>[];

  String? _categoryId;
  String? _brandId;
  ProductCondition _condition = ProductCondition.isNew;
  bool _isActive = true;
  bool _isNewArrival = false;
  bool _isLiquidated = false;
  bool _isComingSoon = false;
  bool _busy = false;
  String? _status;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();

    final p = widget.existing;

    if (p == null) return;

    _name.text = p.name;
    _sku.text = p.sku ?? '';
    _price.text = '${p.price}';
    _salePrice.text = p.discountPrice == null ? '' : '${p.discountPrice}';
    _shortDescription.text = p.shortDescription ?? '';
    _description.text = p.description ?? '';
    _categoryId = p.category?.id.isEmpty == true ? null : p.category?.id;
    _brandId = p.brand?.id.isEmpty == true ? null : p.brand?.id;
    _condition = p.condition;
    _isActive = p.isActive;
    _isNewArrival = p.isNewArrival;
    _isLiquidated = p.isLiquidated;
    _isComingSoon = p.isComingSoon;
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _price.dispose();
    _salePrice.dispose();
    _shortDescription.dispose();
    _description.dispose();
    _initialStock.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos({required bool fromCamera}) async {
    final picker = ImagePicker();

    final picked = fromCamera
        ? [
            ?await picker.pickImage(
              source: ImageSource.camera,
              // Phone cameras produce 4-8MB frames; the storefront never shows
              // them larger than this and the upload is on mobile data.
              maxWidth: 2000,
              imageQuality: 85,
            ),
          ]
        : await picker.pickMultiImage(maxWidth: 2000, imageQuality: 85);

    if (picked.isEmpty) return;

    setState(() => _newPhotos.addAll(picked));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final l = context.l;

    if (_categoryId == null || _brandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_categoryId == null ? l.pickCategory : l.pickBrand),
        ),
      );

      return;
    }

    setState(() {
      _busy = true;
      _status = null;
    });

    final repo = ref.read(productRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final draft = Product(
        // The backend takes an all-zero id as "create".
        id: widget.existing?.id ?? '00000000-0000-0000-0000-000000000000',
        name: _name.text.trim(),
        price: num.parse(_price.text.trim()),
        status: StockStatus.inStock,
        condition: _condition,
        sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        discountPrice: _salePrice.text.trim().isEmpty
            ? null
            : num.tryParse(_salePrice.text.trim()),
        shortDescription: _shortDescription.text.trim().isEmpty
            ? null
            : _shortDescription.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        isActive: _isActive,
        isNewArrival: _isNewArrival,
        isLiquidated: _isLiquidated,
        isComingSoon: _isComingSoon,
      );

      final body = draft.toRequestJson(
        brandId: _brandId!,
        categoryId: _categoryId!,
        initialStock: _isNew && _initialStock.text.trim().isNotEmpty
            ? int.tryParse(_initialStock.text.trim())
            : null,
      );

      final String productId;

      if (_isNew) {
        productId = await repo.create(body);
      } else {
        await repo.update(body);
        productId = widget.existing!.id;
      }

      if (_newPhotos.isNotEmpty) {
        setState(() => _status = l.uploadingPhotos);

        await repo.uploadImages(
          productId: productId,
          files: [
            for (final photo in _newPhotos)
              await MultipartFile.fromFile(photo.path, filename: photo.name),
          ],
          // First photo becomes the cover only when there is no cover yet.
          coverIndex: widget.existing?.images.isEmpty ?? true ? 0 : null,
        );
      }

      ref.invalidate(productListProvider);

      if (!_isNew) ref.invalidate(_productProvider(productId));

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(_isNew ? l.productCreated : l.productSaved)),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));

      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
        });
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));

      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;
    final categories = ref.watch(_categoriesProvider).value ?? const [];
    final brands = ref.watch(_brandsProvider).value ?? const [];
    final existingImages = widget.existing?.images ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l.addProduct : l.editProduct),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: Text(l.save),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            SectionTitle(l.photos),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _PhotoButton(
                    icon: Icons.photo_camera_outlined,
                    label: l.takePhoto,
                    onTap: _busy ? null : () => _pickPhotos(fromCamera: true),
                  ),
                  const SizedBox(width: 8),
                  _PhotoButton(
                    icon: Icons.photo_library_outlined,
                    label: l.chooseFromLibrary,
                    onTap: _busy ? null : () => _pickPhotos(fromCamera: false),
                  ),
                  for (final image in existingImages) ...[
                    const SizedBox(width: 8),
                    EntityThumb(path: image.imagePath, size: 92),
                  ],
                  for (var i = 0; i < _newPhotos.length; i++) ...[
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_newPhotos[i].path),
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => setState(() => _newPhotos.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: c.overlay.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: c.onOverlay,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.productName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.requiredField : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.price),
                    validator: (v) => num.tryParse(v?.trim() ?? '') == null
                        ? l.invalidPrice
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salePrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.salePrice),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sku,
              decoration: InputDecoration(labelText: l.sku),
            ),
            if (_isNew) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _initialStock,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.initialStock),
              ),
            ],
            const SizedBox(height: 24),
            SectionTitle(l.category),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.category),
              items: [
                for (final cat in categories)
                  DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _brandId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.brand),
              items: [
                for (final brand in brands)
                  DropdownMenuItem(
                    value: brand.id,
                    child: Text(brand.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _brandId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductCondition>(
              initialValue: _condition,
              decoration: InputDecoration(labelText: l.condition),
              items: [
                DropdownMenuItem(
                  value: ProductCondition.isNew,
                  child: Text(l.conditionNew),
                ),
                DropdownMenuItem(
                  value: ProductCondition.used,
                  child: Text(l.conditionUsed),
                ),
                DropdownMenuItem(
                  value: ProductCondition.likeNew,
                  child: Text(l.conditionLikeNew),
                ),
              ],
              onChanged: (v) => setState(() => _condition = v ?? _condition),
            ),
            const SizedBox(height: 24),
            SectionTitle(l.description),
            TextFormField(
              controller: _shortDescription,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.shortDescription),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration: InputDecoration(labelText: l.description),
            ),
            const SizedBox(height: 24),
            SectionTitle(l.visibility),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: Text(l.publishedOnline, style: const TextStyle(fontSize: 14)),
                  ),
                  SwitchListTile(
                    value: _isNewArrival,
                    onChanged: (v) => setState(() => _isNewArrival = v),
                    title: Text(l.markNewArrival, style: const TextStyle(fontSize: 14)),
                  ),
                  SwitchListTile(
                    value: _isLiquidated,
                    onChanged: (v) => setState(() => _isLiquidated = v),
                    title: Text(l.markLiquidated, style: const TextStyle(fontSize: 14)),
                  ),
                  SwitchListTile(
                    value: _isComingSoon,
                    onChanged: (v) => setState(() => _isComingSoon = v),
                    title: Text(l.markComingSoon, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_status != null) ...[
              Text(
                _status!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const SizedBox(height: 10),
            ],
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.primaryForeground,
                      ),
                    )
                  : Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: c.textSecondary),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
