import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/inventory.dart';
import '../../models/product.dart';
import '../../widgets/common.dart';
import '../../widgets/sheet.dart';
import 'inventory_screen.dart' show locationsProvider, stockListProvider;

/// Move stock between warehouses and shops.
/// `POST api/admin/stock-transfers` takes 1-500 lines, each quantity > 0.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _note = TextEditingController();
  final _lines = <({Product product, int quantity})>[];

  String? _from;
  String? _to;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _addLine() async {
    final product = await showKomeroSheet<Product>(
      context,
      title: context.l.addProduct,
      builder: (_) => const _ProductPicker(),
    );

    if (product == null) return;

    setState(() => _lines.add((product: product, quantity: 1)));
  }

  Future<void> _submit() async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_from == null || _to == null) return;

    if (_from == _to) {
      messenger.showSnackBar(SnackBar(content: Text(l.sameLocationError)));

      return;
    }

    setState(() => _busy = true);

    try {
      await ref.read(locationRepositoryProvider).transfer(
            StockTransferRequest(
              fromLocationId: _from!,
              toLocationId: _to!,
              note: _note.text.trim(),
              lines: _lines
                  .map((e) => (productId: e.product.id, quantity: e.quantity))
                  .toList(),
            ),
          );

      ref.invalidate(stockListProvider);
      ref.invalidate(locationsProvider);

      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.transferCreated)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));

      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;
    final locations = ref.watch(locationsProvider);

    final ready = _from != null && _to != null && _lines.isNotEmpty && !_busy;

    return Scaffold(
      appBar: AppBar(title: Text(l.transferStock)),
      body: AsyncView(
        value: locations,
        onRetry: () => ref.invalidate(locationsProvider),
        data: (locations) {
          if (locations.length < 2) {
            return EmptyState(
              message: l.noResults,
              icon: Icons.warehouse_outlined,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _from,
                decoration: InputDecoration(labelText: l.transferFrom),
                items: [
                  for (final loc in locations)
                    DropdownMenuItem(value: loc.id, child: Text(loc.name)),
                ],
                onChanged: (v) => setState(() => _from = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _to,
                decoration: InputDecoration(labelText: l.transferTo),
                items: [
                  for (final loc in locations)
                    DropdownMenuItem(value: loc.id, child: Text(loc.name)),
                ],
                onChanged: (v) => setState(() => _to = v),
              ),
              const SizedBox(height: 24),
              SectionTitle(
                l.items,
                trailing: TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l.addProduct),
                ),
              ),
              if (_lines.isEmpty)
                Panel(
                  child: Text(
                    l.noResults,
                    style: TextStyle(fontSize: 13, color: c.textMuted),
                  ),
                )
              else
                Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < _lines.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: i == _lines.length - 1
                                ? null
                                : Border(bottom: BorderSide(color: c.border)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _lines[i].product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: c.text),
                                ),
                              ),
                              IconButton(
                                onPressed: _lines[i].quantity <= 1
                                    ? null
                                    : () => setState(() => _lines[i] = (
                                          product: _lines[i].product,
                                          quantity: _lines[i].quantity - 1,
                                        )),
                                icon: const Icon(Icons.remove, size: 18),
                              ),
                              Text(
                                '${_lines[i].quantity}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: c.text,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _lines[i] = (
                                      product: _lines[i].product,
                                      quantity: _lines[i].quantity + 1,
                                    )),
                                icon: const Icon(Icons.add, size: 18),
                              ),
                              IconButton(
                                onPressed: () => setState(() => _lines.removeAt(i)),
                                icon: Icon(Icons.close, size: 18, color: c.error),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _note,
                maxLength: 1000,
                maxLines: 2,
                decoration: InputDecoration(labelText: l.transferNote),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: ready ? _submit : null,
                child: _busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.primaryForeground,
                        ),
                      )
                    : Text(l.transferStock),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Search-as-you-type product picker, shared by transfers.
class _ProductPicker extends ConsumerStatefulWidget {
  const _ProductPicker();

  @override
  ConsumerState<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<_ProductPicker> {
  final _query = TextEditingController();

  List<Product> _results = const [];
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String term) async {
    if (term.trim().length < 2) {
      setState(() => _results = const []);

      return;
    }

    setState(() => _busy = true);

    try {
      final found = await ref.read(productRepositoryProvider).search(term.trim());

      if (mounted) setState(() => _results = found);
    } on ApiException {
      if (mounted) setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            TextField(
              controller: _query,
              autofocus: true,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: l.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busy
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? EmptyState(message: l.noResults, icon: Icons.search)
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) => ListTile(
                        leading: EntityThumb(path: _results[i].coverImage, size: 40),
                        title: Text(
                          _results[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: _results[i].sku == null
                            ? null
                            : Text(_results[i].sku!),
                        onTap: () => Navigator.pop(context, _results[i]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
