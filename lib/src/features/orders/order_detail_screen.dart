import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/net/api_client.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories.dart';
import '../../l10n_ext.dart';
import '../../models/me.dart';
import '../../models/order.dart';
import '../../widgets/common.dart';
import '../../widgets/delivery_map.dart';
import '../../widgets/sheet.dart';
import '../dashboard/dashboard_screen.dart' show meProvider;
import 'orders_screen.dart' show ordersProvider;

final orderDetailProvider = FutureProvider.family<OrderDetail, String>(
  (ref, id) => ref.watch(orderRepositoryProvider).byId(id),
);

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final order = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(l.orderDetails)),
      body: AsyncView(
        value: order,
        onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        data: (order) => _OrderBody(order: order),
      ),
    );
  }
}

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final tag = context.localeTag;
    final canManage = ref.watch(meProvider).value?.can(Perm.orders) ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.orderNumber(order.orderNumber ?? order.id.split('-').first),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                  StatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                shortDate(order.date, locale: tag),
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
              if (order.channel != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      order.channel == OrderChannel.pos
                          ? Icons.point_of_sale_outlined
                          : Icons.language,
                      size: 14,
                      color: c.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.orderChannelLabel(order.channel!),
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
              if (order.trackingNumber != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 14, color: c.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SelectableText(
                        order.trackingNumber!,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (order.customer != null) ...[
          SectionTitle(l.customer),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customer!.fullName.isEmpty
                      ? l.guestOrder
                      : order.customer!.fullName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                if (order.customer!.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.customer!.email,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
                if (order.customer!.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    order.customer!.phoneNumber,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (order.customer!.phoneNumber.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _launch('tel:${order.customer!.phoneNumber}'),
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: Text(l.callCustomer),
                        ),
                      ),
                    if (order.customer!.phoneNumber.isNotEmpty &&
                        order.customer!.email.isNotEmpty)
                      const SizedBox(width: 10),
                    if (order.customer!.email.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launch(
                            'mailto:${order.customer!.email}'
                            '?subject=${Uri.encodeComponent(l.orderNumber(order.orderNumber ?? order.id))}',
                          ),
                          icon: const Icon(Icons.mail_outline, size: 18),
                          label: Text(l.emailCustomer),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        SectionTitle(l.items),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < order.orderItems.length; i++)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: i == order.orderItems.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: c.border)),
                  ),
                  child: Row(
                    children: [
                      EntityThumb(path: order.orderItems[i].image, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderItems[i].name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: c.text),
                            ),
                            if (order.orderItems[i].sku != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                order.orderItems[i].sku!,
                                style: TextStyle(fontSize: 11, color: c.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${order.orderItems[i].quantity} × '
                        '${money(order.orderItems[i].price, currency: order.currency, locale: tag)}',
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionTitle(l.payment),
        Panel(
          child: Column(
            children: [
              _MoneyRow(
                label: l.subtotal,
                value: money(order.subtotal, currency: order.currency, locale: tag),
              ),
              if (order.tax > 0)
                _MoneyRow(
                  label: l.tax,
                  value: money(order.tax, currency: order.currency, locale: tag),
                ),
              if (order.shippingCost > 0)
                _MoneyRow(
                  label: l.shipping,
                  value:
                      money(order.shippingCost, currency: order.currency, locale: tag),
                ),
              if (order.discount > 0)
                _MoneyRow(
                  label: l.discount,
                  value:
                      '−${money(order.discount, currency: order.currency, locale: tag)}',
                  valueColor: c.success,
                ),
              Divider(height: 20, color: c.border),
              _MoneyRow(
                label: l.total,
                value: money(order.total, currency: order.currency, locale: tag),
                bold: true,
              ),
              if (order.paymentMethod != null || order.paymentStatus != null) ...[
                const SizedBox(height: 12),
                if (order.paymentMethod != null)
                  _MoneyRow(label: l.paymentMethod, value: order.paymentMethod!),
                if (order.paymentStatus != null)
                  _MoneyRow(label: l.paymentStatus, value: order.paymentStatus!),
              ],
            ],
          ),
        ),
        if (order.shippingAddress.isNotEmpty || order.hasPin) ...[
          const SizedBox(height: 20),
          SectionTitle(l.deliveryLocation),
          DeliveryMap(
            address: order.shippingAddress,
            latitude: order.shippingLatitude,
            longitude: order.shippingLongitude,
          ),
        ],
        const SizedBox(height: 24),
        if (!canManage)
          Text(
            l.permissionDenied,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.textMuted),
          )
        else if (order.isPos)
          // A till sale's status is owned by the till, not by this app.
          Panel(
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: c.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.posOrderReadOnly,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          _OrderActions(order: order),
      ],
    );
  }

  static Future<void> _launch(String uri) async {
    final parsed = Uri.parse(uri);

    if (await canLaunchUrl(parsed)) await launchUrl(parsed);
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                color: bold ? c.text : c.textSecondary,
                fontWeight: bold ? FontWeight.w600 : null,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? c.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fulfilment, status changes and cancellation.
///
/// Note on refunds: the backend has no capture or refund endpoint for
/// storefront orders — `Order/update-order-status` with `Refunded` is the only
/// lever, and it records the refund without moving money. The copy says so.
class _OrderActions extends ConsumerStatefulWidget {
  const _OrderActions({required this.order});

  final OrderDetail order;

  @override
  ConsumerState<_OrderActions> createState() => _OrderActionsState();
}

class _OrderActionsState extends ConsumerState<_OrderActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() => _busy = true);

    try {
      await action();

      ref.invalidate(orderDetailProvider(widget.order.id));
      ref.invalidate(ordersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fulfil() async {
    final l = context.l;
    // One draft object owned by this call, shared by the sheet's body and its
    // pinned action, and disposed when the sheet closes.
    final draft = _FulfilDraft(widget.order);

    final ({String? tracking, DateTime? eta})? result;

    try {
      result = await showKomeroSheet<({String? tracking, DateTime? eta})>(
        context,
        title: l.fulfillOrder,
        subtitle: l.orderNumber(widget.order.orderNumber ?? widget.order.id),
        builder: (_) => _FulfilFields(draft: draft),
        actions: [_FulfilSubmit(draft: draft)],
      );
    } finally {
      draft.dispose();
    }

    if (result == null) return;

    final fulfilment = result;

    await _run(
      () => ref.read(orderRepositoryProvider).updateStatus(
            orderId: widget.order.id,
            status: OrderStatus.shipped,
            trackingNumber: fulfilment.tracking,
            estimatedDelivery: fulfilment.eta,
          ),
      l.statusUpdated,
    );
  }

  Future<void> _setStatus(OrderStatus status) async {
    final l = context.l;

    await _run(
      () => ref.read(orderRepositoryProvider).updateStatus(
            orderId: widget.order.id,
            status: status,
          ),
      l.statusUpdated,
    );
  }

  Future<void> _cancel() async {
    final l = context.l;
    final reason = await promptSheet(
      context,
      title: l.cancelOrder,
      label: l.cancelReason,
      confirmLabel: l.cancelOrder,
      destructive: true,
    );

    if (reason == null || reason.isEmpty) return;

    final me = ref.read(meProvider).value;

    if (me == null) return;

    await _run(
      () => ref.read(orderRepositoryProvider).cancel(
            orderId: widget.order.id,
            userId: me.userId,
            reason: reason,
          ),
      l.orderCancelled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.c;
    final status = widget.order.status;

    final canFulfil =
        status == OrderStatus.paid || status == OrderStatus.processing;
    final canDeliver = status == OrderStatus.shipped;
    final canCancel = status == OrderStatus.pending ||
        status == OrderStatus.paid ||
        status == OrderStatus.processing;
    final canRefund =
        status == OrderStatus.paid || status == OrderStatus.delivered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (status == OrderStatus.pending)
          FilledButton.icon(
            onPressed: _busy ? null : () => _setStatus(OrderStatus.processing),
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: Text(l.statusProcessing),
          ),
        if (canFulfil) ...[
          if (status == OrderStatus.pending) const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _busy ? null : _fulfil,
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: Text(l.markAsFulfilled),
          ),
        ],
        if (canDeliver)
          FilledButton.icon(
            onPressed: _busy ? null : () => _setStatus(OrderStatus.delivered),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(l.statusDelivered),
          ),
        if (canRefund) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    final ok = await confirmSheet(
                      context,
                      title: l.markRefunded,
                      message: l.refundWarning,
                      confirmLabel: l.markRefunded,
                    );

                    if (ok) await _setStatus(OrderStatus.refunded);
                  },
            icon: const Icon(Icons.currency_exchange, size: 18),
            label: Text(l.markRefunded),
          ),
        ],
        if (canCancel) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _cancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: c.error,
              side: BorderSide(color: c.error.withValues(alpha: 0.4)),
            ),
            icon: const Icon(Icons.close, size: 18),
            label: Text(l.cancelOrder),
          ),
        ],
      ],
    );
  }
}

/// The in-progress fulfilment, owned by `_fulfil()` so the sheet's body and
/// its pinned action share one source of truth without module-level state.
class _FulfilDraft extends ChangeNotifier {
  _FulfilDraft(OrderDetail order)
      : tracking = TextEditingController(text: order.trackingNumber ?? ''),
        _eta = order.estimatedDelivery;

  final TextEditingController tracking;
  DateTime? _eta;

  DateTime? get eta => _eta;

  set eta(DateTime? value) {
    _eta = value;
    notifyListeners();
  }

  String? get trackingOrNull =>
      tracking.text.trim().isEmpty ? null : tracking.text.trim();

  @override
  void dispose() {
    tracking.dispose();
    super.dispose();
  }
}

/// Tracking number + ETA — the two things "mark as fulfilled" actually sends.
class _FulfilFields extends StatelessWidget {
  const _FulfilFields({required this.draft});

  final _FulfilDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = context.l;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: draft.tracking,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l.trackingNumber,
            hintText: l.trackingNumberHint,
            prefixIcon: const Icon(Icons.qr_code_2_outlined),
          ),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: draft,
          builder: (context, _) => OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    draft.eta ?? DateTime.now().add(const Duration(days: 3)),
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );

              if (picked != null) draft.eta = picked;
            },
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text(
              draft.eta == null
                  ? l.estimatedDelivery
                  : '${l.estimatedDelivery}: '
                      '${draft.eta!.day}.${draft.eta!.month}.${draft.eta!.year}',
            ),
          ),
        ),
      ],
    );
  }
}

class _FulfilSubmit extends StatelessWidget {
  const _FulfilSubmit({required this.draft});

  final _FulfilDraft draft;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => Navigator.pop(
        context,
        (tracking: draft.trackingOrNull, eta: draft.eta),
      ),
      icon: const Icon(Icons.local_shipping_outlined, size: 18),
      label: Text(context.l.markAsFulfilled),
    );
  }
}
