import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/product.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/common.dart';
import '../../widgets/sheet.dart';

/// The parts of the catalog that are lists of names: categories, brands and
/// variant groups. They differ only in which endpoints they call, so they are
/// one screen with three configurations rather than three near-identical ones.
enum CatalogKind { categories, brands, groups }

extension CatalogKindX on CatalogKind {
  String title(L l) => switch (this) {
        CatalogKind.categories => l.categories,
        CatalogKind.brands => l.brands,
        CatalogKind.groups => l.productGroups,
      };

  IconData get icon => switch (this) {
        CatalogKind.categories => Icons.category_outlined,
        CatalogKind.brands => Icons.sell_outlined,
        CatalogKind.groups => Icons.layers_outlined,
      };

  /// Variant groups are created and filled from the product side — this screen
  /// lists them, but editing one in place is not a thing the API offers.
  bool get isEditable => this != CatalogKind.groups;
}

final catalogListProvider =
    FutureProvider.family<List<NamedRef>, CatalogKind>((ref, kind) {
  final catalog = ref.watch(catalogRepositoryProvider);
  final products = ref.watch(productRepositoryProvider);

  return switch (kind) {
    CatalogKind.categories => products.categories(),
    CatalogKind.brands => products.brands(),
    CatalogKind.groups => catalog.productGroups(),
  };
});

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, required this.kind});

  final CatalogKind kind;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String _query = '';

  Future<void> _edit({NamedRef? existing}) async {
    final l = context.l;
    final saved = await showCatalogEditor(
      context,
      ref: ref,
      kind: widget.kind,
      existing: existing,
    );

    if (saved != true || !mounted) return;

    ref.invalidate(catalogListProvider(widget.kind));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.saved)));
  }

  Future<void> _delete(NamedRef item) async {
    final l = context.l;
    final confirmed = await showKomeroSheet<bool>(
      context,
      title: l.deleteItem(item.name),
      subtitle: l.deleteCatalogWarning,
      builder: (_) => const SizedBox.shrink(),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.delete),
        ),
      ],
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final catalog = ref.read(catalogRepositoryProvider);

    try {
      if (widget.kind == CatalogKind.categories) {
        await catalog.deleteCategory(item.id);
      } else {
        await catalog.deleteBrand(item.id);
      }

      ref.invalidate(catalogListProvider(widget.kind));
      messenger.showSnackBar(SnackBar(content: Text(l.deleted)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;
    final kind = widget.kind;
    final items = ref.watch(catalogListProvider(kind));
    final query = _query.trim().toLowerCase();

    return AppScaffold(
      title: kind.title(l),
      actions: [
        if (kind.isEditable || kind == CatalogKind.groups)
          IconButton(
            tooltip: l.addNew,
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
          ),
        const SizedBox(width: 4),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(catalogListProvider(kind));
                await ref.read(catalogListProvider(kind).future);
              },
              child: AsyncView(
                value: items,
                onRetry: () => ref.invalidate(catalogListProvider(kind)),
                data: (all) {
                  // Categories nest under each other; searching flattens the
                  // tree so a match under an unmatched parent stays reachable.
                  final matches = query.isEmpty
                      ? orderAsTree(
                          all,
                          idOf: (item) => item.id,
                          parentOf: (item) => item.parentId,
                        )
                      : [
                          for (final item in all)
                            if (item.name.toLowerCase().contains(query))
                              (item: item, depth: 0),
                        ];

                  if (matches.isEmpty) {
                    return EmptyState(message: l.noResults, icon: kind.icon);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: matches.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, indent: 16, color: c.border),
                    itemBuilder: (_, i) {
                      final item = matches[i].item;
                      final depth = matches[i].depth;

                      return ListTile(
                        contentPadding: EdgeInsets.only(left: 16 + depth * 18, right: 8),
                        leading: Icon(
                          depth == 0 ? kind.icon : Icons.subdirectory_arrow_right,
                          size: 20,
                          color: c.textMuted,
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(fontSize: 15, color: c.text),
                        ),
                        trailing: kind.isEditable
                            ? IconButton(
                                tooltip: l.delete,
                                onPressed: () => _delete(item),
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: c.textMuted,
                                ),
                              )
                            : null,
                        onTap: kind.isEditable
                            ? () => _edit(existing: item)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Create or rename one catalog entry. Returns true when something was saved.
Future<bool?> showCatalogEditor(
  BuildContext context, {
  required WidgetRef ref,
  required CatalogKind kind,
  NamedRef? existing,
}) {
  final l = context.l;
  final name = TextEditingController(text: existing?.name ?? '');

  return showKomeroSheet<bool>(
    context,
    title: existing == null ? l.addNew : l.edit,
    subtitle: kind.title(l),
    builder: (_) => TextField(
      controller: name,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: l.name),
    ),
    actions: [
      _SaveCatalogButton(ref: ref, kind: kind, existing: existing, name: name),
    ],
  );
}

class _SaveCatalogButton extends StatefulWidget {
  const _SaveCatalogButton({
    required this.ref,
    required this.kind,
    required this.existing,
    required this.name,
  });

  final WidgetRef ref;
  final CatalogKind kind;
  final NamedRef? existing;
  final TextEditingController name;

  @override
  State<_SaveCatalogButton> createState() => _SaveCatalogButtonState();
}

class _SaveCatalogButtonState extends State<_SaveCatalogButton> {
  bool _busy = false;

  Future<void> _save() async {
    final name = widget.name.text.trim();

    if (name.isEmpty) return;

    setState(() => _busy = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final catalog = widget.ref.read(catalogRepositoryProvider);

    try {
      switch (widget.kind) {
        case CatalogKind.categories:
          await catalog.saveCategory(id: widget.existing?.id, name: name);
        case CatalogKind.brands:
          await catalog.saveBrand(id: widget.existing?.id, name: name);
        case CatalogKind.groups:
          await catalog.createProductGroup(name);
      }

      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));

      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;

    return FilledButton(
      onPressed: _busy ? null : _save,
      child: _busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.primaryForeground,
              ),
            )
          : Text(l.save),
    );
  }
}
