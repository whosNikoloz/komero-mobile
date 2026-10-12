import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/net/api_client.dart';
import '../core/theme/tokens.dart';
import '../l10n_ext.dart';
import '../models/order.dart';

/// Section heading above a group of cards.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: context.c.textSecondary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The card surface used everywhere — one border radius, one border colour.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: child,
    );

    if (onTap == null) return body;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: body,
    );
  }
}

/// A headline number with its period-over-period delta.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.deltaPercent,
    this.icon,
  });

  final String label;
  final String value;
  final num? deltaPercent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final delta = deltaPercent;
    final up = (delta ?? 0) >= 0;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 15, color: c.textMuted),
              if (icon != null) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: c.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: c.text,
            ),
          ),
          if (delta != null && delta != 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  up ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: up ? c.success : c.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${up ? '+' : ''}${delta.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: up ? c.success : c.error,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    context.l.vsLastMonth,
                    style: TextStyle(fontSize: 11, color: c.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Order status as a coloured dot plus a label.
///
/// Flat on purpose: no pill background, no border, no radius — the Komero
/// design system is a flat system, and a bordered capsule around every row's
/// status competed with the row itself. The colour carries the meaning and the
/// dot keeps it readable for anyone who cannot separate the hues.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final color = switch (status) {
      OrderStatus.pending => c.warning,
      OrderStatus.paid => c.success,
      OrderStatus.processing => c.info,
      OrderStatus.shipped => c.primary,
      OrderStatus.delivered => c.success,
      OrderStatus.cancelled => c.error,
      OrderStatus.refunded => c.textMuted,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          context.l.orderStatusLabel(status),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Product/order thumbnail. Image paths from the API may be relative.
class EntityThumb extends StatelessWidget {
  const EntityThumb({super.key, this.path, this.size = 48, this.icon});

  final String? path;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final url = absoluteImageUrl(path);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: c.surfaceHover,
        child: url == null
            ? Icon(icon ?? Icons.inventory_2_outlined, size: size * 0.45, color: c.textMuted)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Icon(
                  icon ?? Icons.broken_image_outlined,
                  size: size * 0.45,
                  color: c.textMuted,
                ),
                placeholder: (_, _) => const SizedBox.shrink(),
              ),
      ),
    );
  }
}

/// Resolves whatever the API put in `imagePath` into a URL the phone can load.
///
/// The catalog stores absolute URLs on `img.komero.ge`, but it stores them as
/// **http://**. Android blocks cleartext traffic by default (API 28+), so those
/// loads fail silently and every product shows the placeholder icon. The host
/// serves the same bytes over TLS and 301s http → https anyway, so the scheme
/// is upgraded here rather than by opening a cleartext hole in the manifest.
///
/// Relative paths (`/assets/...`) are resolved against the API base, matching
/// `resolveImageUrl` in commerce/lib/utils.ts.
String? absoluteImageUrl(String? path) {
  final raw = path?.trim();

  if (raw == null || raw.isEmpty) return null;

  if (raw.startsWith('https://')) return raw;

  if (raw.startsWith('http://')) {
    return 'https://${raw.substring('http://'.length)}';
  }

  final base = kApiBaseUrl.endsWith('/')
      ? kApiBaseUrl
      : '$kApiBaseUrl/';

  return '$base${raw.startsWith('/') ? raw.substring(1) : raw}';
}

/// Centred empty state.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon, this.action});

  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.inbox_outlined, size: 44, color: c.textDisabled),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 14),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// Error state that knows the difference between "no permission", "wrong
/// store" and a plain failure, because those need different words.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    final message = switch (error) {
      ApiException e when e.isForbidden => l.permissionDenied,
      ApiException e when e.isTenantUnresolved => l.storeNotFound,
      ApiException e => e.message,
      _ => l.somethingWentWrong,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 44, color: c.error),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders an AsyncValue with the three states handled once, instead of in
/// every screen.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(error: e, onRetry: onRetry),
    );
  }
}

/// Money formatting. The backend returns GEL for Georgian tenants but carries
/// the currency on the order, so callers pass it where they have it.
String money(num value, {String currency = 'GEL', String? locale}) {
  final symbol = switch (currency.toUpperCase()) {
    'GEL' => '₾',
    'USD' => '\$',
    'EUR' => '€',
    'RUB' => '₽',
    _ => '$currency ',
  };

  return NumberFormat.currency(
    locale: locale,
    symbol: symbol,
    decimalDigits: value % 1 == 0 ? 0 : 2,
  ).format(value);
}

String compactNumber(num value, {String? locale}) =>
    NumberFormat.compact(locale: locale).format(value);

String shortDate(DateTime? value, {String? locale}) =>
    value == null ? '—' : DateFormat.MMMd(locale).add_Hm().format(value.toLocal());
