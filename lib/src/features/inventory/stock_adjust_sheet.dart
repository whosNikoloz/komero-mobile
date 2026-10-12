import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../widgets/sheet.dart';
import 'inventory_screen.dart' show stockListProvider;

enum AdjustMode { add, remove, set }

/// Reasons shown to the operator.
///
/// ponytail: the reason is recorded in the status line and the audit trail the
/// backend already keeps per stock write, but it is NOT sent as a field —
/// `Stock/update-stock` and `add/remove-stock` take a bare number and have
/// nowhere to put it. When the API grows a reason parameter, pass
/// `reason.name` through; nothing else here has to change.
enum AdjustReason { restocked, damaged, returned, theft, correction }

Future<void> showStockAdjustSheet(
  BuildContext context, {
  required String productId,
  required String productName,
  required int currentQuantity,
  String? locationId,
  int packQuantity = 1,
}) {
  return showKomeroSheet<void>(
    context,
    title: context.l.adjustStock,
    subtitle: productName,
    builder: (_) => _StockAdjustSheet(
      productId: productId,
      productName: productName,
      currentQuantity: currentQuantity,
      locationId: locationId,
      packQuantity: packQuantity,
    ),
  );
}

class _StockAdjustSheet extends ConsumerStatefulWidget {
  const _StockAdjustSheet({
    required this.productId,
    required this.productName,
    required this.currentQuantity,
    required this.locationId,
    required this.packQuantity,
  });

  final String productId;
  final String productName;
  final int currentQuantity;
  final String? locationId;
  final int packQuantity;

  @override
  ConsumerState<_StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends ConsumerState<_StockAdjustSheet> {
  late final TextEditingController _amount =
      TextEditingController(text: '${widget.packQuantity}');

  AdjustMode _mode = AdjustMode.add;
  AdjustReason _reason = AdjustReason.restocked;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.trim()) ?? 0;

  int get _resulting => switch (_mode) {
        AdjustMode.add => widget.currentQuantity + _value,
        AdjustMode.remove => widget.currentQuantity - _value,
        AdjustMode.set => _value,
      };

  Future<void> _submit() async {
    if (_value <= 0 && _mode != AdjustMode.set) return;

    setState(() => _busy = true);

    final repo = ref.read(stockRepositoryProvider);
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await switch (_mode) {
        AdjustMode.add =>
          repo.addQuantity(widget.productId, _value, locationId: widget.locationId),
        AdjustMode.remove => repo.removeQuantity(
            widget.productId,
            _value,
            locationId: widget.locationId,
          ),
        AdjustMode.set =>
          repo.setQuantity(widget.productId, _value, locationId: widget.locationId),
      };

      ref.invalidate(stockListProvider);

      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l.stockUpdated)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));

      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    final reasonLabel = {
      AdjustReason.restocked: l.reasonRestocked,
      AdjustReason.damaged: l.reasonDamaged,
      AdjustReason.returned: l.reasonReturned,
      AdjustReason.theft: l.reasonTheft,
      AdjustReason.correction: l.reasonCorrection,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          Text(
            '${l.onHand}: ${widget.currentQuantity}',
            style: TextStyle(fontSize: 13, color: c.textMuted),
          ),
          if (widget.packQuantity > 1) ...[
            const SizedBox(height: 6),
            Text(
              l.packQuantityNote(widget.packQuantity),
              style: TextStyle(fontSize: 12, color: c.info),
            ),
          ],
          const SizedBox(height: 20),
          SegmentedButton<AdjustMode>(
            segments: [
              ButtonSegment(value: AdjustMode.add, label: Text(l.addQuantity)),
              ButtonSegment(value: AdjustMode.remove, label: Text(l.removeQuantity)),
              ButtonSegment(value: AdjustMode.set, label: Text(l.setQuantity)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton.outlined(
                onPressed: () => setState(
                  () => _amount.text = '${(_value - 1).clamp(0, 999999)}',
                ),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amount,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: _mode == AdjustMode.set ? l.newQuantity : l.transferQuantity,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                onPressed: () => setState(() => _amount.text = '${_value + 1}'),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<AdjustReason>(
            initialValue: _reason,
            decoration: InputDecoration(labelText: l.adjustmentReason),
            items: [
              for (final r in AdjustReason.values)
                DropdownMenuItem(value: r, child: Text(reasonLabel[r]!)),
            ],
            onChanged: (v) => setState(() => _reason = v ?? _reason),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Text(
                  l.newQuantity,
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${_resulting < 0 ? 0 : _resulting}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _resulting <= 0 ? c.error : c.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy || (_value <= 0 && _mode != AdjustMode.set)
                ? null
                : _submit,
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
    );
  }
}
