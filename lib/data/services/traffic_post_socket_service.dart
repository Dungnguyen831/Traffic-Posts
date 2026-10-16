import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/traffic_post_model.dart';
import '../models/traffic_post_realtime_event.dart';

/// Service quản lý kết nối STOMP over WebSocket cho bài viết giao thông realtime
class TrafficPostSocketService {
  StompClient? _client;
  bool _hasConnectedBefore = false;

  bool get isConnected => _client?.connected ?? false;

  /// Chuyển đổi BASE_URL sang WebSocket URL tương ứng
  /// http://192.168.0.104:8080 -> ws://192.168.0.104:8080/ws
  /// https://domain.com -> wss://domain.com/ws
  static String resolveWebSocketUrl([String? rawBaseUrl]) {
    final base = (rawBaseUrl != null && rawBaseUrl.isNotEmpty)
        ? rawBaseUrl
        : (dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080');

    String wsUrl = base.trim();
    if (wsUrl.endsWith('/')) {
      wsUrl = wsUrl.substring(0, wsUrl.length - 1);
    }

    if (wsUrl.startsWith('https://')) {
      wsUrl = 'wss://${wsUrl.substring(8)}';
    } else if (wsUrl.startsWith('http://')) {
      wsUrl = 'ws://${wsUrl.substring(7)}';
    } else if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
      wsUrl = 'ws://$wsUrl';
    }

    if (!wsUrl.endsWith('/ws')) {
      wsUrl = '$wsUrl/ws';
    }

    return wsUrl;
  }

  /// Bắt đầu kết nối STOMP client
  Future<void> connect({
    required String webSocketUrl,
    required String jwt,
    required void Function(TrafficPostModel post) onNewPost,
    required Future<void> Function() onReconnect,
    void Function(dynamic error)? onError,
  }) async {
    // Nếu client cũ đang hoạt động, hủy trước khi mở kết nối mới
    if (_client != null) {
      disconnect();
    }

    final connectedCompleter = Completer<void>();
    debugPrint('[TrafficPostSocket] Bắt đầu kết nối tới: $webSocketUrl');

    _client = StompClient(
      config: StompConfig(
        url: webSocketUrl,
        stompConnectHeaders: {
          'Authorization': 'Bearer $jwt',
        },
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (StompFrame frame) async {
          debugPrint('[TrafficPostSocket] ✅ Kết nối STOMP thành công');

          // Đăng ký topic bài viết giao thông
          _client?.subscribe(
            destination: '/topic/traffic-posts',
            callback: (StompFrame frame) {
              final body = frame.body;
              if (body == null || body.isEmpty) return;

              try {
                final json = jsonDecode(body) as Map<String, dynamic>;
                final event = TrafficPostRealtimeEvent.fromJson(json);

                if (event.eventType == 'NEW_POST') {
                  debugPrint(
                    '[TrafficPostSocket] 📩 NEW_POST nhận được: ${event.data.id} - ${event.data.content}',
                  );
                  onNewPost(event.data);
                } else {
                  debugPrint(
                    '[TrafficPostSocket] ℹ️ Bỏ qua eventType: ${event.eventType}',
                  );
                }
              } catch (error) {
                // Ghi log parse error, không làm crash màn map
                debugPrint('[TrafficPostSocket] ⚠️ Lỗi parse JSON event: $error');
              }
            },
          );

          if (!_hasConnectedBefore) {
            _hasConnectedBefore = true;
            if (!connectedCompleter.isCompleted) {
              connectedCompleter.complete();
            }
          } else {
            debugPrint('[TrafficPostSocket] 🔄 Reconnected thành công! Bắt đầu đồng bộ REST...');
            try {
              await onReconnect();
            } catch (e) {
              debugPrint('[TrafficPostSocket] ⚠️ Lỗi khi đồng bộ REST sau reconnect: $e');
            }
          }
        },
        onStompError: (StompFrame frame) {
          debugPrint('[TrafficPostSocket] ❌ Lỗi STOMP: ${frame.body}');
          onError?.call(frame.body);
          if (!connectedCompleter.isCompleted) {
            connectedCompleter.complete();
          }
        },
        onWebSocketError: (dynamic error) {
          debugPrint('[TrafficPostSocket] ⚠️ Lỗi WebSocket: $error');
          onError?.call(error);
          if (!connectedCompleter.isCompleted) {
            // Tự động reconnect bởi package sau reconnectDelay
            connectedCompleter.complete();
          }
        },
        onDisconnect: (StompFrame frame) {
          debugPrint('[TrafficPostSocket] 🔌 STOMP ngắt kết nối');
        },
      ),
    );

    _client?.activate();

    // Giới hạn thời gian chờ kết nối ban đầu tối đa 5s để không block UI nếu server chưa online
    return connectedCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint(
          '[TrafficPostSocket] ⏱ Quá thời gian chờ STOMP connect ban đầu (5s), tiếp tục chạy nền...',
        );
      },
    );
  }

  /// Ngắt kết nối an toàn khi rời màn hình
  void disconnect() {
    debugPrint('[TrafficPostSocket] Ngắt kết nối STOMP client');
    try {
      _client?.deactivate();
    } catch (e) {
      debugPrint('[TrafficPostSocket] Lỗi khi deactivate: $e');
    }
    _client = null;
    _hasConnectedBefore = false;
  }
}
