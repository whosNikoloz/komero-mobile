import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'models/order.dart';

export '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  /// `context.l.signIn` — shorter than L.of(context) at every call site.
  L get l => L.of(this);

  /// The active language tag, for intl's number and date formatters.
  String get localeTag => Localizations.localeOf(this).toLanguageTag();
}

/// Enum labels live here so no screen has to switch over them twice.
extension OrderLabels on L {
  String orderStatusLabel(OrderStatus status) => switch (status) {
        OrderStatus.pending => statusPending,
        OrderStatus.paid => statusPaid,
        OrderStatus.processing => statusProcessing,
        OrderStatus.shipped => statusShipped,
        OrderStatus.delivered => statusDelivered,
        OrderStatus.cancelled => statusCancelled,
        OrderStatus.refunded => statusRefunded,
      };

  String orderChannelLabel(OrderChannel channel) => switch (channel) {
        OrderChannel.webShop => channelWebShop,
        OrderChannel.b2b => channelB2B,
        OrderChannel.pos => channelPos,
      };
}
