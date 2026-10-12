import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tokens.dart';
import '../data/branding.dart';
import 'common.dart';

/// The Komero mark. Ships with the app, so it is always available — including
/// on the sign-in screen before any store is known.
class KomeroLogo extends StatelessWidget {
  const KomeroLogo({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/komero-logo.png',
      width: size,
      height: size,
      // The mark is a solid blue disc; no decoration needed around it.
      filterQuality: FilterQuality.medium,
    );
  }
}

/// "Powered by Komero" strip — the platform mark where the store's own
/// branding is the main event.
class KomeroByline extends StatelessWidget {
  const KomeroByline({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const KomeroLogo(size: 16),
        const SizedBox(width: 7),
        Text(
          'Komero',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.textMuted,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// The store's own logo, falling back to its initials on a tinted square when
/// the tenant has not uploaded one.
class StoreLogo extends StatelessWidget {
  const StoreLogo({super.key, required this.branding, this.size = 36});

  final StoreBranding? branding;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final url = absoluteImageUrl(branding?.logoFor(dark: dark));

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Text(
        branding?.initials ?? '·',
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: c.primary,
        ),
      ),
    );

    if (url == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: Container(
        width: size,
        height: size,
        // Many tenant logos are transparent PNGs drawn for a white header, so
        // they need a light plate to stay legible in dark mode.
        color: Colors.white,
        padding: EdgeInsets.all(size * 0.08),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) => fallback,
          placeholder: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Store logo + name, for an app bar. Shows nothing until the config lands, so
/// the bar never jumps between two different titles.
class StoreIdentity extends ConsumerWidget {
  const StoreIdentity({super.key, required this.fallbackTitle});

  final String fallbackTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final branding = ref.watch(storeBrandingProvider).value;

    if (branding == null) return Text(fallbackTitle);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StoreLogo(branding: branding, size: 30),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branding.displayName.isEmpty ? fallbackTitle : branding.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                  height: 1.1,
                ),
              ),
              Text(
                fallbackTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: c.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
