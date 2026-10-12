import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/net/api_client.dart';
import '../core/session.dart';
import '../models/order.dart';

/// Live order feed off `GET /orders/stream`.
///
/// The endpoint is Server-Sent Events and takes its credentials in the query
/// string (`access_token`, `domain`) rather than headers — that is how the web
/// admin's EventSource reaches it, and it is the only auth shape it accepts.
/// Events arrive as `event: order-event` frames with a JSON payload.
class OrderStream {
  OrderStream(this._session);

  final SessionController _session;

  final _controller = StreamController<OrderEvent>.broadcast();
  final _dio = Dio();

  CancelToken? _cancel;
  Timer? _retry;
  int _attempt = 0;
  bool _closed = false;

  Stream<OrderEvent> get events => _controller.stream;

  Future<void> connect() async {
    final token = _session.token;
    final domain = _session.domain;

    if (_closed || token == null || domain == null) return;

    _cancel = CancelToken();

    try {
      final res = await _dio.get<ResponseBody>(
        '${kApiBaseUrl}orders/stream',
        queryParameters: {'access_token': token, 'domain': domain},
        cancelToken: _cancel,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          receiveTimeout: Duration.zero, // a stream never "finishes receiving"
        ),
      );

      _attempt = 0;

      await _readFrames(res.data!.stream);
    } catch (_) {
      // Fall through to the backoff below.
    }

    if (!_closed) _scheduleReconnect();
  }

  /// SSE frames are separated by a blank line; we only care about `data:` lines.
  Future<void> _readFrames(Stream<List<int>> bytes) async {
    final buffer = StringBuffer();

    await for (final chunk in bytes.transform(utf8.decoder)) {
      buffer.write(chunk);

      final text = buffer.toString();
      final frames = text.split(RegExp(r'\r?\n\r?\n'));

      // The last piece may be a partial frame — keep it for the next chunk.
      buffer
        ..clear()
        ..write(frames.removeLast());

      for (final frame in frames) {
        final data = frame
            .split(RegExp(r'\r?\n'))
            .where((l) => l.startsWith('data:'))
            .map((l) => l.substring(5).trim())
            .join();

        if (data.isEmpty) continue;

        try {
          _controller.add(
            OrderEvent.fromJson(jsonDecode(data) as Map<String, dynamic>),
          );
        } catch (_) {
          // A frame we cannot parse is not worth dropping the stream for.
        }
      }
    }
  }

  void _scheduleReconnect() {
    _attempt++;

    // ponytail: capped exponential backoff, 2s → 60s. Good enough for a phone
    // that loses signal in a lift; swap for connectivity-driven reconnect if
    // battery drain ever shows up.
    final seconds = (1 << _attempt).clamp(2, 60);

    _retry?.cancel();
    _retry = Timer(Duration(seconds: seconds), connect);
  }

  void dispose() {
    _closed = true;
    _retry?.cancel();
    _cancel?.cancel();
    _controller.close();
  }
}

/// Live while someone is signed in; torn down on sign-out.
final orderStreamProvider = Provider<OrderStream?>((ref) {
  final session = ref.watch(sessionProvider);

  if (!session.isAuthenticated) return null;

  final stream = OrderStream(ref.watch(sessionProvider.notifier));

  stream.connect();
  ref.onDispose(stream.dispose);

  return stream;
});

/// The last event seen, for screens that just want to refresh on any change.
final orderEventsProvider = StreamProvider<OrderEvent>((ref) {
  final stream = ref.watch(orderStreamProvider);

  return stream?.events ?? const Stream.empty();
});
