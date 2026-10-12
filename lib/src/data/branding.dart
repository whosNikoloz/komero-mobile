import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/api_client.dart';
import '../core/session.dart';

/// The store's own identity — **name and logo only**.
///
/// The tenant config also carries a full theme (primary colour, surfaces,
/// fonts). The app deliberately ignores it: this is Komero's operator tool, so
/// it wears Komero's palette on every tenant. Do not read theme colours here —
/// add a semantic token to [KomeroColors] instead.
class StoreBranding {
  const StoreBranding({
    required this.name,
    this.shortName,
    this.logo,
    this.logoLight,
    this.logoDark,
  });

  final String name;
  final String? shortName;
  final String? logo;
  final String? logoLight;
  final String? logoDark;

  /// Picks the variant made for the current theme, falling back to the main
  /// logo. A tenant that sets only `logo` gets it in both themes.
  String? logoFor({required bool dark}) {
    final preferred = dark ? logoDark : logoLight;

    return _firstNonEmpty([preferred, logo, logoLight, logoDark]);
  }

  String get displayName => name.isNotEmpty ? name : (shortName ?? '');

  /// Two letters for the fallback avatar when a tenant has no logo at all.
  String get initials {
    final words =
        displayName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.characters2;
    }

    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  factory StoreBranding.fromConfig(Map<String, dynamic> config) {
    // The endpoint answers either the config itself or `{ config: {...} }`,
    // and siteConfig is sometimes nested one level deeper.
    final root = (config['config'] ?? config) as Map;
    final site = (root['siteConfig'] ?? root) as Map;

    return StoreBranding(
      name: '${site['name'] ?? ''}',
      shortName: site['shortName'] as String?,
      logo: site['logo'] as String?,
      logoLight: site['logoLight'] as String?,
      logoDark: site['logoDark'] as String?,
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v;
    }

    return null;
  }
}

extension on String {
  String get characters2 =>
      (length >= 2 ? substring(0, 2) : substring(0, 1)).toUpperCase();
}

class BrandingRepository {
  BrandingRepository(this._api);

  final KomeroApi _api;

  /// `GET Tenant/tenant-configuration?host=<domain>` — unauthenticated, which
  /// is what lets the login screen show the store's logo the moment its
  /// address is typed, before any credentials exist.
  Future<StoreBranding> forDomain(String domain) async {
    final host = SessionController.normalizeDomain(domain);

    final res = await _api.get<dynamic>(
      'Tenant/tenant-configuration',
      query: {'host': host},
      headers: {'X-Client-Domain': host},
    );

    if (res is Map) return StoreBranding.fromConfig(res.cast<String, dynamic>());

    throw ApiException(404, 'No store configuration at $host');
  }
}

final brandingRepositoryProvider =
    Provider((ref) => BrandingRepository(ref.watch(apiProvider)));

/// Branding for an arbitrary domain — used by the login screen while the
/// operator is still typing, so it is keyed by the domain rather than by the
/// session.
final brandingForDomainProvider =
    FutureProvider.family<StoreBranding, String>((ref, domain) async {
  return ref.watch(brandingRepositoryProvider).forDomain(domain);
});

/// Branding for the store the operator is signed into.
final storeBrandingProvider = FutureProvider<StoreBranding?>((ref) async {
  final domain = ref.watch(sessionProvider).domain;

  if (domain == null) return null;

  return ref.watch(brandingRepositoryProvider).forDomain(domain);
});
