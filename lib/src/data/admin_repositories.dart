import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/api_client.dart';

/// The store-management areas beyond the catalog: discounts, the blog and the
/// FAQ. They are the parts of the web admin an operator actually adds things
/// to from a phone — the rest of that panel is configuration, which is a
/// desk job.
///
/// Promotions live on `admin/promotions` and the blog on `api/blog/*`, both on
/// the same host and the same operator token as everything else; the FAQ is on
/// the `FAQ` controller like the catalog.

// ─── Promotions ──────────────────────────────────────────────────────────────

/// Mirrors the backend's integer status. Everything the phone shows hangs off
/// this, so it is modelled rather than passed around as a bare int.
enum PromotionStatus {
  draft(1),
  scheduled(2),
  active(3),
  paused(4),
  expired(5),
  exhausted(6),
  archived(7);

  const PromotionStatus(this.wire);

  final int wire;

  static PromotionStatus from(Object? value) {
    final n = value is int ? value : int.tryParse('$value');

    for (final s in PromotionStatus.values) {
      if (s.wire == n) return s;
    }

    return PromotionStatus.draft;
  }

  /// A live promotion can be paused and a paused one resumed; the rest are
  /// end states the phone does not try to move.
  bool get canPause => this == PromotionStatus.active;
  bool get canResume => this == PromotionStatus.paused || this == PromotionStatus.draft;
}

class Promotion {
  Promotion({
    required this.id,
    required this.name,
    required this.status,
    required this.isLiveNow,
    required this.summary,
    required this.redemptionCount,
    required this.couponCount,
    required this.isCoupon,
  });

  factory Promotion.fromJson(Map j) => Promotion(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        status: PromotionStatus.from(j['status']),
        isLiveNow: j['isLiveNow'] == true,
        summary: '${j['summary'] ?? j['description'] ?? ''}',
        redemptionCount: (j['redemptionCount'] as num?)?.toInt() ?? 0,
        couponCount: (j['couponCount'] as num?)?.toInt() ?? 0,
        // 2 is Coupon, 1 is Automatic.
        isCoupon: '${j['activationType']}' == '2',
      );

  final String id;
  final String name;
  final PromotionStatus status;
  final bool isLiveNow;
  final String summary;
  final int redemptionCount;
  final int couponCount;
  final bool isCoupon;
}

/// How much comes off. The admin panel offers six benefit types with their own
/// field sets; the phone creates the two that cover almost every discount an
/// operator types in on the move, and the web panel keeps the rest.
enum DiscountKind { percent, amount }

class PromotionRepository {
  PromotionRepository(this._api);

  final KomeroApi _api;

  Future<List<Promotion>> list({String? search, bool includeArchived = false}) async {
    final res = await _api.get<Map<String, dynamic>>('admin/promotions', query: {
      'page': 1,
      'pageSize': 100,
      if (search != null && search.isNotEmpty) 'search': search,
      if (includeArchived) 'status': PromotionStatus.archived.wire,
    });

    final items = res['items'];

    return items is List
        ? items.map((e) => Promotion.fromJson(e as Map)).toList()
        : const [];
  }

  /// Creates the straightforward case: a percentage or amount off the whole
  /// order, either automatic or behind one coupon code.
  Future<String> create({
    required String name,
    required DiscountKind kind,
    required num value,
    String? couponCode,
    DateTime? endsAt,
  }) async {
    final res = await _api.post<Map<String, dynamic>>('admin/promotions', body: {
      'name': name,
      'activationType': couponCode == null || couponCode.isEmpty ? 1 : 2,
      'combinability': 1, // Exclusive — the safe default for a quick discount.
      'benefit': {
        'type': kind == DiscountKind.percent ? 'PercentOff' : 'AmountOff',
        if (kind == DiscountKind.percent) 'percent': value else 'amount': value,
        'appliesToOrder': true,
      },
      'targets': [
        {'targetType': 1, 'targetId': null, 'isExclusion': false},
      ],
      'endAtLocal': endsAt?.toIso8601String(),
    });

    final id = '${res['id'] ?? ''}';

    if (id.isNotEmpty && couponCode != null && couponCode.isNotEmpty) {
      await _api.post<dynamic>('admin/promotions/$id/coupons', body: {
        'code': couponCode,
      });
    }

    return id;
  }

  Future<void> activate(String id) =>
      _api.post<dynamic>('admin/promotions/$id/activate');

  Future<void> pause(String id) => _api.post<dynamic>('admin/promotions/$id/pause');

  /// Archive, not erase — the backend keeps redemption history.
  Future<void> archive(String id) => _api.delete<dynamic>('admin/promotions/$id');
}

final promotionRepositoryProvider =
    Provider((ref) => PromotionRepository(ref.watch(apiProvider)));

// ─── Blog ────────────────────────────────────────────────────────────────────

class BlogPost {
  BlogPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.isPublished,
  });

  factory BlogPost.fromJson(Map j) => BlogPost(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        excerpt: '${j['excerpt'] ?? ''}',
        isPublished: j['isPublished'] == true ||
            j['publishedAt'] != null ||
            '${j['status']}'.toLowerCase() == 'published',
      );

  final String id;
  final String title;
  final String excerpt;
  final bool isPublished;
}

class BlogRepository {
  BlogRepository(this._api);

  final KomeroApi _api;

  Future<List<BlogPost>> posts({String? search}) async {
    final res = await _api.get<dynamic>('api/blog/posts', query: {
      'page': 1,
      'pageSize': 100,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    final items = res is List ? res : (res['items'] ?? res['data'] ?? const []);

    return (items as List).map((e) => BlogPost.fromJson(e as Map)).toList();
  }

  /// Posts are created as drafts and published separately, which is why the
  /// phone can write one on the way somewhere and publish it later.
  Future<String> createPost({
    required String title,
    required String content,
    String excerpt = '',
  }) async {
    final res = await _api.post<Map<String, dynamic>>('api/blog/posts', body: {
      'title': title,
      'content': content,
      'excerpt': excerpt,
    });

    return '${res['id'] ?? ''}';
  }

  Future<void> updatePost({
    required String id,
    required String title,
    required String content,
    String excerpt = '',
  }) =>
      _api.put<void>('api/blog/posts/$id', body: {
        'title': title,
        'content': content,
        'excerpt': excerpt,
      });

  Future<void> publish(String id) =>
      _api.post<dynamic>('api/blog/posts/$id/publish');

  Future<void> deletePost(String id) => _api.delete<void>('api/blog/posts/$id');
}

final blogRepositoryProvider =
    Provider((ref) => BlogRepository(ref.watch(apiProvider)));

// ─── FAQ ─────────────────────────────────────────────────────────────────────

class Faq {
  Faq({required this.id, required this.question, required this.answer});

  factory Faq.fromJson(Map j) => Faq(
        id: '${j['id'] ?? ''}',
        question: '${j['question'] ?? ''}',
        answer: '${j['answer'] ?? ''}',
      );

  final String id;
  final String question;
  final String answer;
}

class FaqRepository {
  FaqRepository(this._api);

  final KomeroApi _api;

  Future<List<Faq>> list() async {
    final res = await _api.get<List<dynamic>>('FAQ/get-all-faqs');

    return res.map((e) => Faq.fromJson(e as Map)).toList();
  }

  Future<void> save({
    String? id,
    required String question,
    required String answer,
  }) {
    // The create endpoint wants the display flags too; they are not worth a
    // control on the phone, so a FAQ written here is live and unpinned.
    final body = {
      'id': ?id,
      'question': question,
      'answer': answer,
      'isActive': true,
      'isFeatured': false,
      'orderNum': 0,
    };

    return id == null
        ? _api.post<dynamic>('FAQ/add-faq', body: body)
        : _api.put<void>('FAQ/update-faq', body: body);
  }

  Future<void> delete(String id) => _api.delete<void>('FAQ/delete-faq-by-$id');
}

final faqRepositoryProvider =
    Provider((ref) => FaqRepository(ref.watch(apiProvider)));
