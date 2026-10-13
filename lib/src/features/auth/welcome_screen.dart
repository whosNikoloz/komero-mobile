import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/tokens.dart';
import '../../l10n_ext.dart';
import '../../widgets/branding.dart';
import '../../widgets/language_picker.dart';
import 'login_screen.dart';

/// The first thing a signed-out operator sees. It exists so the app opens on
/// something that says what Komero is, instead of on a form asking for a store
/// address — the sign-in form is one tap away behind Continue.
///
/// It is deliberately stateless and unskippable-by-flag: a returning operator
/// taps once, which is cheaper than a stored "seen" flag that can go stale.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        // Everything is laid out against the viewport height, but inside a
        // scroll view: on a normal phone the blocks space out and nothing
        // scrolls, and on a phone set to a very large system font the screen
        // scrolls instead of overflowing.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 12, 0),
                    child: Row(
                      children: const [
                        KomeroLogo(size: 32),
                        Spacer(),
                        // Same reasoning as on the sign-in form: an operator
                        // who cannot read the screen must be able to change
                        // language without first getting into the app.
                        LanguageButton(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                    child: Column(
                      children: [
                        Text(
                          l.welcomeTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.7,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.45,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _PreviewCarousel(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Text(l.continueLabel),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const KomeroByline(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two rows of app cards drifting past in opposite directions — the same trick
/// the Shopify sign-in uses, except the tiles here are pieces of the actual
/// admin (revenue, an order, stock) rather than stock photography, which this
/// app ships none of.
///
/// The numbers are illustrative, not fetched: nobody is signed in yet, so
/// there is no store to read them from.
class _PreviewCarousel extends StatelessWidget {
  const _PreviewCarousel();

  /// Fixed, so the cards stay dense and the composition keeps its proportions
  /// on every screen. Letting the rows stretch is what made the cards look
  /// half-empty on a tall phone. The card's 1px border eats 2 of it, which is
  /// what the per-card budgets below are measured against.
  static const _rowHeight = 134.0;
  static const _rowGap = 12.0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return ExcludeSemantics(
      // Decoration, not information: a screen reader announcing fake revenue
      // figures would be actively misleading.
      child: SizedBox(
        height: _rowHeight * 2 + _rowGap,
        child: Stack(
          children: [
            // Soft brand wash behind the rows, so they read as lifted off the
            // page rather than pasted onto a flat background.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [c.primary.withValues(alpha: 0.10), Colors.transparent],
                    radius: 0.75,
                  ),
                ),
              ),
            ),
            // The cards are a picture of the app, not text to read — they are
            // already hidden from screen readers, and the headline, subtitle
            // and button around them still follow the system font size.
            // Pinning the mock's own scale is what keeps a fixed-height card
            // from overflowing on a phone set to large text.
            MediaQuery.withNoTextScaling(
              child: Column(
                children: const [
                  SizedBox(
                    height: _rowHeight,
                    child: _Marquee(
                      speed: 18,
                      cards: [_RevenueCard(), _OrderCard(), _LiveCard()],
                    ),
                  ),
                  SizedBox(height: _rowGap),
                  SizedBox(
                    height: _rowHeight,
                    // Opposite direction and a different pace, so the two rows
                    // never lock into one block sliding sideways.
                    child: _Marquee(
                      speed: -13,
                      cards: [_StockCard(), _FunnelCard(), _ProductCard()],
                    ),
                  ),
                ],
              ),
            ),
            // Fade the rows out at both edges instead of letting cards get
            // guillotined by the screen border.
            Positioned.fill(
              child: IgnorePointer(child: _EdgeFade(color: c.background)),
            ),
          ],
        ),
      ),
    );
  }
}

/// An endlessly repeating horizontal strip. [speed] is logical pixels per
/// second; negative runs the other way.
class _Marquee extends StatefulWidget {
  const _Marquee({required this.cards, required this.speed});

  final List<Widget> cards;
  final double speed;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  // A huge initial offset gives the reversed row room to scroll backwards
  // without ever hitting zero in a session.
  static const _origin = 100000.0;

  final _scroll = ScrollController(initialScrollOffset: _origin);

  late final Ticker _ticker;
  double _offset = _origin;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond;
    _last = elapsed;

    // The first frame's dt is the whole time since the ticker started, which
    // would make the row jump; and a client is needed before jumpTo.
    if (dt <= 0 || dt > 0.1 || !_scroll.hasClients) return;

    _offset += widget.speed * dt;
    _scroll.jumpTo(_offset);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      // Driven by the ticker, so a drag would only fight it. The screen's
      // real control is the Continue button underneath.
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: widget.cards[i % widget.cards.length],
      ),
    );
  }
}

/// Transparent-to-background gradients down the left and right edges.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _band(begin: Alignment.centerLeft, end: Alignment.centerRight),
        const Spacer(),
        _band(begin: Alignment.centerRight, end: Alignment.centerLeft),
      ],
    );
  }

  Widget _band({required Alignment begin, required Alignment end}) {
    return SizedBox(
      width: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Shared frame for every card in the strip — one place owns the padding, the
/// radius and the shadow, which is most of what keeps the row looking like one
/// set rather than six unrelated boxes.
class _Card extends StatelessWidget {
  const _Card({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.overlay.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// The small caption every card opens with, optionally with its own dot or
/// icon. Fixed height, so the content below starts on the same line in every
/// card of the row.
class _CardHead extends StatelessWidget {
  const _CardHead(this.text, {this.leading});

  final String text;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SizedBox(
      height: 16,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Flexible(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: c.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figures line up column-wise and never shift width as they animate, which is
/// the detail that makes a number read as a real readout.
const _figures = [FontFeature.tabularFigures()];

class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return _Card(
      width: 196,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead('${l.revenue} · ${l.today}'),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // A figure is never ellipsised — it would read as a different
              // number. The lari sign falls back to a wider face in some
              // locales, so let the whole amount shrink instead.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₾ 4,280',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      fontFeatures: _figures,
                      color: c.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              _Delta(value: '12%', tone: c.success),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: CustomPaint(painter: _SparklinePainter(color: c.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return _Card(
      width: 214,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(l.orders),
          const SizedBox(height: 8),
          // Two rows, not three: a third would squeeze the row spacing below
          // what the card's padding sets, and the card would read as cramped.
          _OrderRow(id: '#1042', status: l.statusPaid, tone: c.success),
          const SizedBox(height: 8),
          _OrderRow(id: '#1041', status: l.statusShipped, tone: c.info),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return _Card(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(
            l.liveNow,
            leading: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
            ),
          ),
          const Spacer(),
          Text(
            '18',
            style: TextStyle(
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              fontFeatures: _figures,
              color: c.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.navHome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return _Card(
      width: 206,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(l.lowStock),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.inventory_2_outlined, size: 17, color: c.warning),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.lowStockCount(3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return _Card(
      width: 184,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(l.dashboard),
          const SizedBox(height: 10),
          _Bar(fraction: 1.0, value: '1,204', tone: c.primary),
          const SizedBox(height: 7),
          _Bar(
            fraction: 0.52,
            value: '628',
            tone: c.primary.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 7),
          _Bar(fraction: 0.24, value: '291', tone: c.success),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return _Card(
      width: 192,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(l.navProducts),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.sell_outlined, size: 18, color: c.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₾ 149',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          fontFeatures: _figures,
                          color: c.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _Pill(text: l.statusDelivered, tone: c.success),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// A funnel step: the bar itself plus its count, so the card carries a readout
/// rather than three abstract stripes.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.value, required this.tone});

  final double fraction;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: c.surface,
              valueColor: AlwaysStoppedAnimation(tone),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              fontFeatures: _figures,
              color: c.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({required this.value, required this.tone});

  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_upward, size: 10, color: tone),
          const SizedBox(width: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              fontFeatures: _figures,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tone),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.id, required this.status, required this.tone});

  final String id;
  final String status;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(Icons.receipt_long_outlined, size: 13, color: c.textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            id,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              fontFeatures: _figures,
              color: c.text,
            ),
          ),
        ),
        Flexible(child: _Pill(text: status, tone: tone)),
      ],
    );
  }
}

/// A fixed, hand-picked curve rather than random data: it has to look the same
/// on every build, and a generated walk would sometimes come out flat or ugly.
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color});

  final Color color;

  static const _points = <double>[0.30, 0.18, 0.44, 0.36, 0.58, 0.48, 0.74, 0.66, 0.90];

  @override
  void paint(Canvas canvas, Size size) {
    // Keep the stroke and the end dot inside the box, so neither is clipped by
    // the card's padding edge.
    const inset = 4.0;
    final top = inset;
    final bottom = size.height - inset;
    final step = (size.width - inset) / (_points.length - 1);

    double y(double v) => bottom - (bottom - top) * v;

    final path = Path();

    for (final (i, v) in _points.indexed) {
      final dx = i * step;

      if (i == 0) {
        path.moveTo(dx, y(v));
      } else {
        path.lineTo(dx, y(v));
      }
    }

    // Fill under the line first, so the stroke sits on top of its own wash.
    final fill = Path.from(path)
      ..lineTo(size.width - inset, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // A dot on the latest point, the way the real dashboard chart marks today.
    canvas.drawCircle(
      Offset(size.width - inset, y(_points.last)),
      3,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.color != color;
}
