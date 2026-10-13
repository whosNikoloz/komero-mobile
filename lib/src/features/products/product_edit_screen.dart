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
import '../../widgets/editor.dart';
import '../../widgets/sheet.dart';
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

  /// Camera or library — asked once, here, instead of standing as two
  /// permanent tiles in the photo strip.
  Future<void> _choosePhotoSource() async {
    final l = context.l;

    final fromCamera = await showKomeroSheet<bool>(
      context,
      title: l.addPhoto,
      builder: (sheetContext) => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.takePhoto),
            onTap: () => Navigator.of(sheetContext).pop(true),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.chooseFromLibrary),
            onTap: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    );

    if (fromCamera == null || !mounted) return;

    await _pickPhotos(fromCamera: fromCamera);
  }

  /// A long field gets the whole screen. The controller stays the state, so
  /// the save path is untouched by where the text was typed.
  Future<void> _editText({
    required String title,
    required TextEditingController controller,
  }) async {
    final text = await editText(
      context,
      title: title,
      subtitle: _name.text.trim().isEmpty ? null : _name.text.trim(),
      initial: controller.text,
    );

    if (text == null || !mounted) return;

    setState(() => controller.text = text);
  }

  Future<void> _pick({
    required String title,
    required List<NamedRef> items,
    required String? selected,
    required ValueChanged<String?> onPicked,
  }) async {
    final chosen = await pickOne<NamedRef>(
      context,
      title: title,
      items: items,
      labelOf: (item) => item.name,
      selected: _refOf(items, selected),
    );

    // null is "backed out"; a result carrying a null value is "cleared it".
    if (chosen == null || !mounted) return;

    onPicked(chosen.value?.id);
  }

  static NamedRef? _refOf(List<NamedRef> items, String? id) {
    for (final item in items) {
      if (item.id == id) return item;
    }

    return null;
  }

  static String? _nameOf(List<NamedRef> items, String? id) =>
      _refOf(items, id)?.name;

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
                  // The add tile sits after the photos, not before them: it is
                  // the end of the strip you reach by scrolling past what is
                  // already there.
                  if (existingImages.isNotEmpty || _newPhotos.isNotEmpty)
                    const SizedBox(width: 8),
                  _AddPhotoTile(onTap: _busy ? null : _choosePhotoSource),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: c.text,
              ),
              decoration: InputDecoration(
                hintText: l.productName,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
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
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  EditorRow(
                    icon: Icons.category_outlined,
                    label: _categoryId == null
                        ? l.selectValue(l.category)
                        : l.category,
                    value: _nameOf(categories, _categoryId),
                    onTap: () => _pick(
                      title: l.category,
                      items: categories,
                      selected: _categoryId,
                      onPicked: (id) => setState(() => _categoryId = id),
                    ),
                  ),
                  const _RowDivider(),
                  EditorRow(
                    icon: Icons.sell_outlined,
                    label: _brandId == null ? l.selectValue(l.brand) : l.brand,
                    value: _nameOf(brands, _brandId),
                    onTap: () => _pick(
                      title: l.brand,
                      items: brands,
                      selected: _brandId,
                      onPicked: (id) => setState(() => _brandId = id),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  EditorRow(
                    label: _shortDescription.text.trim().isEmpty
                        ? l.addValue(l.shortDescription)
                        : l.shortDescription,
                    value: _shortDescription.text,
                    onTap: () => _editText(
                      title: l.shortDescription,
                      controller: _shortDescription,
                    ),
                  ),
                  const _RowDivider(),
                  EditorRow(
                    label: _description.text.trim().isEmpty
                        ? l.addValue(l.description)
                        : l.description,
                    value: _description.text,
                    onTap: () => _editText(
                      title: l.description,
                      controller: _description,
                    ),
                  ),
                ],
              ),
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

/// The tile at the end of the photo strip.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Icon(Icons.add, size: 26, color: c.textSecondary),
      ),
    );
  }
}

/// Hairline between two [EditorRow]s inside one panel.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 48, color: context.c.border);
  }
}
