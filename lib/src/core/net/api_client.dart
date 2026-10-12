import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session.dart';

/// Default backend. Overridable at build time:
/// `flutter run --dart-define=KOMERO_API_URL=https://api.komero.ge/`
const kApiBaseUrl = String.fromEnvironment(
  'KOMERO_API_URL',
  defaultValue: 'https://api.komero.ge/',
);

/// Thrown for every non-2xx answer, carrying the backend's unified error shape
/// (`{ statusCode, errorCode, message, traceId, details }`).
class ApiException implements Exception {
  ApiException(this.status, this.message, {this.errorCode, this.details});

  final int status;
  final String message;
  final String? errorCode;
  final Object? details;

  bool get isAuth => status == 401 || errorCode == 'auth_required';
  bool get isTenantUnresolved => errorCode == 'tenant_not_resolved';
  bool get isForbidden => status == 403 || errorCode == 'permission_denied';

  @override
  String toString() => message;
}

/// The two headers every Komero admin request needs:
///   `Authorization: Bearer <jwt>`    — who you are   (POST /User/login)
///   `X-Client-Domain: <store host>`  — which store   (resolves the tenant DB)
///
/// The JWT is tenant-agnostic; the domain header is what picks the store. Same
/// token + different domain = different store.
class KomeroApi {
  KomeroApi(this._session)
      : dio = Dio(
          BaseOptions(
            baseUrl: kApiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            // We own error mapping, so never let Dio throw on status alone.
            validateStatus: (_) => true,
            headers: {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final domain = _session.domain;
          final token = _session.token;

          if (domain != null) options.headers['X-Client-Domain'] = domain;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Operator JWTs have no refresh token — a 401 means re-login, so drop
          // the session here rather than letting every screen handle it.
          if (response.statusCode == 401 && _session.token != null) {
            _session.onUnauthorized();
          }
          handler.next(response);
        },
      ),
    );
  }

  final Dio dio;
  final SessionController _session;

  /// `MAIN: 0` marks an endpoint that reads the per-tenant database
  /// (`/tenant/config/*`). `MAIN: 1` is platform-level only. Sending the wrong
  /// one answers 500 with a ConnectionString error, so it is explicit per call.
  static Map<String, String> mainHeader(int value) => {'MAIN': '$value'};

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) =>
      _send<T>(() => dio.get(path, queryParameters: query, options: Options(headers: headers)));

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) =>
      _send<T>(() => dio.post(
            path,
            data: body,
            queryParameters: query,
            options: Options(headers: headers),
          ));

  Future<T> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) =>
      _send<T>(() => dio.put(
            path,
            data: body,
            queryParameters: query,
            options: Options(headers: headers),
          ));

  Future<T> delete<T>(String path, {Map<String, dynamic>? query}) =>
      _send<T>(() => dio.delete(path, queryParameters: query));

  Future<T> _send<T>(Future<Response<dynamic>> Function() run) async {
    final Response<dynamic> res;

    try {
      res = await run();
    } on DioException catch (e) {
      throw ApiException(0, e.message ?? 'Network error');
    }

    final status = res.statusCode ?? 0;

    if (status < 200 || status >= 300) throw _toException(status, res.data);

    // Endpoints that answer 204 / empty body are typed as void by the caller.
    if (res.data == null) return null as T;

    return res.data as T;
  }

  ApiException _toException(int status, dynamic data) {
    if (data is Map) {
      return ApiException(
        status,
        (data['message'] ?? data['error'] ?? 'Request failed ($status)').toString(),
        errorCode: data['errorCode']?.toString() ?? data['error']?.toString(),
        details: data['details'],
      );
    }

    final text = data?.toString();

    return ApiException(
      status,
      text == null || text.isEmpty ? 'Request failed ($status)' : text,
    );
  }
}

final apiProvider = Provider<KomeroApi>((ref) {
  return KomeroApi(ref.watch(sessionProvider.notifier));
});
