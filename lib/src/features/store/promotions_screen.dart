import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/admin_repositories.dart';
import '../../l10n_ext.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/common.dart';
import '../../widgets/sheet.dart';

final promotionsProvider = FutureProvider<List<Promotion>>(
  (ref) => ref.watch(promotionRepositoryProvider).list(),
);

/// Discounts and promo codes. The web panel builds the complicated ones —
/// tiered, per-category, stacking rules; this is for the discount an operator
/// decides on in the shop and wants live in the next minute.
class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final c = context.c;
    final promotions = ref.watch(promotionsProvider);

    return AppScaffold(
      title: l.promotions,
      actions: [
        IconButton(
          tooltip: l.addNew,
          onPressed: () => _create(context, ref),
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 4),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(promotionsProvider);
          await ref.read(promotionsProvider.future);
        },
        child: AsyncView(
          value: promotions,
          onRetry: () => ref.invalidate(promotionsProvider),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                message: l.noResults,
                icon: Icons.local_offer_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, indent: 16, color: c.border),
              itemBuilder: (_, i) => _PromotionTile(promotion: items[i]),
            );
          },
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showKomeroSheet<bool>(
      context,
      title: context.l.newDiscount,
      builder: (_) => _NewDiscountForm(ref: ref),
    );

    if (created == true) ref.invalidate(promotionsProvider);
  }
}

class _PromotionTile extends ConsumerStatefulWidget {
  const _PromotionTile({required this.promotion});

  final Promotion promotion;

  @override
  ConsumerState<_PromotionTile> createState() => _PromotionTileState();
}

class _PromotionTileState extends ConsumerState<_PromotionTile> {
  bool _busy = false;

  Future<void> _run(Future<void> Function(PromotionRepository repo) action) async {
    setState(() => _busy = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      await action(ref.read(promotionRepositoryProvider));
      ref.invalidate(promotionsProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final p = widget.promotion;

    final (statusLabel, statusTone) = switch (p.status) {
      PromotionStatus.active => (l.statusActive, c.success),
      PromotionStatus.paused => (l.statusPaused, c.warning),
      PromotionStatus.scheduled => (l.statusScheduled, c.info),
      PromotionStatus.draft => (l.statusDraft, c.textMuted),
      _ => (l.statusEnded, c.textMuted),
    };

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      title: Text(
        p.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.text),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            StatusDot(label: statusLabel, color: statusTone),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                p.isCoupon
                    ? l.couponCount(p.couponCount)
                    : (p.summary.isEmpty ? l.automaticDiscount : p.summary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
      trailing: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: c.textMuted),
              onSelected: (action) => switch (action) {
                'pause' => _run((repo) => repo.pause(p.id)),
                'resume' => _run((repo) => repo.activate(p.id)),
                _ => _run((repo) => repo.archive(p.id)),
              },
              itemBuilder: (_) => [
                if (p.status.canPause)
                  PopupMenuItem(value: 'pause', child: Text(l.pause)),
                if (p.status.canResume)
                  PopupMenuItem(value: 'resume', child: Text(l.activate)),
                PopupMenuItem(value: 'archive', child: Text(l.archive)),
              ],
            ),
    );
  }
}

/// Name, percent or amount, and optionally a code. Everything else the API
/// wants is a sensible fixed choice (whole order, exclusive) rather than a
/// control, because those are the answers for a discount typed on a phone.
class _NewDiscountForm extends ConsumerStatefulWidget {
  const _NewDiscountForm({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_NewDiscountForm> createState() => _NewDiscountFormState();
}

class _NewDiscountFormState extends ConsumerState<_NewDiscountForm> {
  final _name = TextEditingController();
  final _value = TextEditingController();
  final _code = TextEditingController();

  DiscountKind _kind = DiscountKind.percent;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = num.tryParse(_value.text.trim());
    final name = _name.text.trim();

    if (name.isEmpty || value == null) return;

    setState(() => _busy = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(promotionRepositoryProvider).create(
            name: name,
            kind: _kind,
            value: value,
            couponCode: _code.text.trim(),
          );

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.name),
        ),
        const SizedBox(height: 12),
        SegmentedButton<DiscountKind>(
          segments: [
            ButtonSegment(value: DiscountKind.percent, label: Text(l.percentOff)),
            ButtonSegment(value: DiscountKind.amount, label: Text(l.amountOff)),
          ],
          selected: {_kind},
          onSelectionChanged: (s) => setState(() => _kind = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _kind == DiscountKind.percent ? '%' : l.amountOff,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: l.couponCode,
            helperText: l.couponCodeHelp,
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
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
        ),
      ],
    );
  }
}
