/// `GET /User/me` — the operator plus their membership in the store resolved
/// from `X-Client-Domain`. Exactly one tenant comes back, never a list.
class Me {
  Me({
    required this.userId,
    required this.email,
    this.username,
    required this.globalRole,
    required this.isPlatformAdmin,
    this.tenant,
  });

  final String userId;
  final String email;
  final String? username;
  final String globalRole;
  final bool isPlatformAdmin;
  final TenantMembership? tenant;

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        userId: '${j['userId']}',
        email: '${j['email'] ?? ''}',
        username: j['username'] as String?,
        globalRole: '${j['globalRole'] ?? ''}',
        isPlatformAdmin: j['isPlatformAdmin'] == true,
        tenant: j['tenant'] == null
            ? null
            : TenantMembership.fromJson(j['tenant'] as Map<String, dynamic>),
      );

  /// Same rule as the web admin's `canFromMe`: platform admin and store Owner
  /// get everything, a Member needs the explicit permission key.
  bool can(String key) {
    if (isPlatformAdmin) return true;

    final t = tenant;

    if (t == null) return false;
    if (t.role == 'Owner') return true;

    return t.permissions.contains(key);
  }

  String get displayName =>
      (username != null && username!.isNotEmpty) ? username! : email;
}

class TenantMembership {
  TenantMembership({
    required this.tenantId,
    required this.role,
    required this.permissions,
  });

  final String tenantId;

  /// `Owner` or `Member`.
  final String role;
  final List<String> permissions;

  factory TenantMembership.fromJson(Map<String, dynamic> j) => TenantMembership(
        tenantId: '${j['tenantId']}',
        role: '${j['role'] ?? 'Member'}',
        permissions: (j['permissions'] as List?)
                ?.map((e) => '$e')
                .toList(growable: false) ??
            const [],
      );
}

/// Permission keys the mobile app gates on.
abstract final class Perm {
  static const analytics = 'analytics.view';
  static const orders = 'orders.manage';
  static const products = 'products.manage';
}
