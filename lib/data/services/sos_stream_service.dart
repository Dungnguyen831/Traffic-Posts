import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:traffic_app/data/repositories/sos_repository.dart';

import '../../services/storage_service.dart';
import '../../modules/emergency/controllers/emergency_controller.dart';
import '../models/sos_model.dart';

/// Trạng thái kết nối SSE
enum SosConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  noNetwork,
  error,
}

/// SosStreamService quản lý kết nối SSE tới /sos/stream
/// Xử lý đầy đủ: mất mạng, có lại mạng, background/foreground, token hết hạn
class SosStreamService extends GetxService with WidgetsBindingObserver {
  // ─── Reactive state ───────────────────────────────────────────────────────
  final connectionStatus = SosConnectionStatus.disconnected.obs;
  final sosList = <SosResponseDTO>[].obs;
  final lastError = ''.obs;
  final SosRepository _sosRepo = SosRepository();

  // ─── Internals ────────────────────────────────────────────────────────────
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  HttpClient? _httpClient;
  StreamSubscription<String>? _sseSubscription;

  bool _hasNetwork = true;
  bool _appInForeground = true;
  bool _isConnecting = false;
  bool _disposed = false;

  // Exponential backoff
  int _retryCount = 0;
  static const int _maxRetries = 10;
  static const Duration _baseDelay = Duration(seconds: 2);

  Timer? _reconnectTimer;
  Timer? _watchdogTimer;
  Timer? _networkPollingTimer;
  static const Duration _watchdogTimeout = Duration(seconds: 15);
  static const Duration _networkPollingInterval = Duration(seconds: 4);

  // ─── Getter shortcut ──────────────────────────────────────────────────────
  static SosStreamService get to => Get.find<SosStreamService>();

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _listenConnectivity();
    debugPrint('[SOS-SSE] Service khởi động');

    _fetchExistingSos(); 
    connect();
  }

  @override
  void onClose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _reconnectTimer?.cancel();
    _disconnect();
    super.onClose();
  }

  // ─── AppLifecycle: background / foreground ────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App về foreground
      _appInForeground = true;
      debugPrint(
        '[SOS-SSE] App về foreground — status: ${connectionStatus.value}',
      );
      if (connectionStatus.value != SosConnectionStatus.connected &&
          _hasNetwork) {
        debugPrint('[SOS-SSE] Reconnect sau khi về foreground');
        _scheduleReconnect(immediately: true);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App vào background - ngắt kết nối để tiết kiệm pin
      _appInForeground = false;
      debugPrint('[SOS-SSE] App vào background — ngắt kết nối');
      _disconnect();
      connectionStatus.value = SosConnectionStatus.disconnected;
    }
  }

  // ─── Connectivity monitoring ──────────────────────────────────────────────

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);

      if (!_hasNetwork && hasNet) {
        // Vừa có lại mạng
        _hasNetwork = true;
        _retryCount = 0;
        debugPrint('[SOS-SSE] ✅ [Event] Có lại mạng (${results.last})');
        if (_appInForeground) {
          _networkPollingTimer?.cancel();
          _networkPollingTimer = null;
          _isConnecting = false; // đảm bảo không bị block
          _reconnectTimer?.cancel();
          _reconnectTimer = null;
          debugPrint('[SOS-SSE] → Gọi _startSse() từ connectivity event');
          _startSse();
        }
      } else if (_hasNetwork && !hasNet) {
        // Vừa mất mạng
        _hasNetwork = false;
        debugPrint('[SOS-SSE] ⚠️ [Event] Mất mạng');
        _disconnect();
        connectionStatus.value = SosConnectionStatus.noNetwork;
        _startNetworkPolling();
      } else {
        debugPrint(
          '[SOS-SSE] [Event] connectivity thay đổi: $results (không xử lý)',
        );
      }
    });
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Khởi động kết nối (reset retry count)
  void connect() {
    if (_disposed) return;
    _retryCount = 0;
    _startSse();
  }

  /// Ngắt kết nối thủ công
  void disconnect() {
    _reconnectTimer?.cancel();
    _disconnect();
    connectionStatus.value = SosConnectionStatus.disconnected;
  }

  // ─── SSE core logic ───────────────────────────────────────────────────────

  Future<void> _startSse() async {
    if (_isConnecting || _disposed) return;
    if (!_hasNetwork) {
      connectionStatus.value = SosConnectionStatus.noNetwork;
      return;
    }
    if (!_appInForeground) return;

    _isConnecting = true;
    connectionStatus.value = _retryCount > 0
        ? SosConnectionStatus.reconnecting
        : SosConnectionStatus.connecting;

    debugPrint(
      '[SOS-SSE] Bắt đầu kết nối${_retryCount > 0 ? " (retry #$_retryCount)" : ""}',
    );

    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      final token = StorageService.to.getToken() ?? '';
      final uri = Uri.parse('$baseUrl/sos/stream');
      debugPrint('[SOS-SSE] → GET $uri');

      _httpClient = HttpClient();
      final request = await _httpClient!.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();

      // Token hết hạn
      if (response.statusCode == 401) {
        debugPrint('[SOS-SSE] 401 Unauthorized — thử refresh token');
        _httpClient?.close(force: true);
        _isConnecting = false;
        await _handleUnauthorized();
        return;
      }

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // Kết nối thành công
      debugPrint(
        '[SOS-SSE] ✅ Kết nối thành công — HTTP ${response.statusCode}',
      );
      _retryCount = 0;
      _isConnecting = false;
      connectionStatus.value = SosConnectionStatus.connected;
      lastError.value = '';
      _networkPollingTimer?.cancel(); // dừng polling khi đã connected
      _networkPollingTimer = null;
      _resetWatchdog();

      // Parse SSE stream
      _sseSubscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _onSseLine,
            onError: _onSseError,
            onDone: _onSseDone,
            cancelOnError: false,
          );
    } catch (e) {
      _isConnecting = false;
      _onSseError(e);
    }
  }

  String _sseBuffer = '';

  void _onSseLine(String line) {
    _resetWatchdog(); // reset mỗi khi nhận bất kỳ line nào
    if (line.isEmpty) {
      // Blank line = end of event, parse buffer
      if (_sseBuffer.isNotEmpty) {
        _parseSseEvent(_sseBuffer.trim());
        _sseBuffer = '';
      }
      return;
    }
    // Accumulate event lines
    _sseBuffer += '$line\n';
  }

  void _parseSseEvent(String raw) {
    // SSE format:
    //   event: <type>
    //   data: <json>
    String? dataLine;
    for (final line in raw.split('\n')) {
      if (line.startsWith('data:')) {
        dataLine = line.substring(5).trim();
      }
    }
    if (dataLine == null || dataLine.isEmpty) return;
    // Bỏ qua plain-text messages từ server (vd: "SSE connection established")
    if (!dataLine.startsWith('{')) return;

    try {
      final json = jsonDecode(dataLine) as Map<String, dynamic>;
      final sos = SosResponseDTO.fromJson(json);
      // cập nhật xóa hoặc thêm mới vào list
      if (sos.status == 'RESOLVED' || sos.status == 'CANCELLED') {
        sosList.removeWhere((s) => s.sosId == sos.sosId);
        debugPrint('[SOS-SSE] 🗑️ Đã rút ghim SOS khỏi bản đồ: ${sos.sosId}');
        return; 
      }

      // Update or add to list
      final idx = sosList.indexWhere((s) => s.sosId == sos.sosId);
      if (idx >= 0) {
        debugPrint(
          '[SOS-SSE] 🔄 Cập nhật SOS: ${sos.sosId} — status: ${sos.status}',
        );
        sosList[idx] = sos;
      } else {
        debugPrint('[SOS-SSE] 🆕 SOS mới: ${sos.sosId} — ${sos.address}');
        sosList.insert(0, sos);
      }
    } catch (e) {
      debugPrint('[SOS-SSE] ⚠️ Không parse được SSE event: $e\nRaw: $dataLine');
    }
  }

  void _onSseError(dynamic error) {
    _sseSubscription?.cancel();
    _httpClient?.close(force: true);
    _isConnecting = false;

    if (_disposed) return;

    final errMsg = error.toString();
    lastError.value = errMsg;
    debugPrint('[SOS-SSE] ❌ Lỗi stream: $errMsg');

    if (!_hasNetwork) {
      connectionStatus.value = SosConnectionStatus.noNetwork;
      return;
    }

    connectionStatus.value = SosConnectionStatus.error;
    _scheduleReconnect();
  }

  void _onSseDone() {
    _sseSubscription?.cancel();
    _httpClient?.close(force: true);
    _isConnecting = false;

    if (_disposed) return;
    debugPrint('[SOS-SSE] Stream đóng bởi server — thử reconnect');
    if (!_hasNetwork) {
      connectionStatus.value = SosConnectionStatus.noNetwork;
      return;
    }
    if (!_appInForeground) return;

    // Server đóng stream - thử kết nối lại
    _scheduleReconnect();
  }

  void _disconnect() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _networkPollingTimer?.cancel();
    _networkPollingTimer = null;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    _isConnecting = false;
    _sseBuffer = '';
  }

  // ─── Watchdog: force reconnect nếu im lặng quá lâu ─────────────────────
  // ─── Network polling: fallback cho onConnectivityChanged không tin cậy ───

  void _startNetworkPolling() {
    _networkPollingTimer?.cancel();
    debugPrint(
      '[SOS-SSE] 🔄 Bắt đầu polling mạng mỗi ${_networkPollingInterval.inSeconds}s',
    );
    _networkPollingTimer = Timer.periodic(_networkPollingInterval, (_) async {
      if (_disposed || !_appInForeground) return;
      final results = await Connectivity().checkConnectivity();
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      debugPrint(
        '[SOS-SSE] [Polling] check: $results — hasNet=$hasNet _hasNetwork=$_hasNetwork',
      );
      if (hasNet && !_hasNetwork) {
        _networkPollingTimer?.cancel();
        _networkPollingTimer = null;
        _hasNetwork = true;
        _retryCount = 0;
        _isConnecting = false; // đảm bảo không bị block
        debugPrint(
          '[SOS-SSE] ✅ [Polling] Có lại mạng — gọi _startSse() trực tiếp',
        );
        _startSse();
      }
    });
  }

  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(_watchdogTimeout, () {
      if (_disposed || !_appInForeground) return;
      debugPrint(
        '[SOS-SSE] ⏱ Watchdog: ${_watchdogTimeout.inSeconds}s không có data — force reconnect',
      );
      _disconnect();
      _scheduleReconnect(immediately: true);
    });
  }

  // ─── Retry with exponential backoff ──────────────────────────────────────

  void _scheduleReconnect({bool immediately = false}) {
    if (_disposed || _reconnectTimer?.isActive == true) return;
    if (_retryCount >= _maxRetries) {
      connectionStatus.value = SosConnectionStatus.error;
      lastError.value = 'Đã thử kết nối lại $_maxRetries lần không thành công';
      return;
    }

    final delay = immediately
        ? Duration.zero
        : _baseDelay * (1 << _retryCount.clamp(0, 6)); // tối đa ~128s

    _retryCount++;
    debugPrint('[SOS-SSE] ⏳ Retry #$_retryCount sau ${delay.inSeconds}s');
    _reconnectTimer = Timer(delay, () {
      if (!_disposed && _hasNetwork && _appInForeground) {
        _startSse();
      }
    });
  }

  // ─── Token refresh khi 401 ───────────────────────────────────────────────

  Future<void> _handleUnauthorized() async {
    if (_disposed) return;
    connectionStatus.value = SosConnectionStatus.error;
    lastError.value = 'Phiên đăng nhập hết hạn';

    final storage = StorageService.to;
    final credentials = storage.getCredentials();
    if (credentials == null) {
      Get.offAllNamed('/login');
      return;
    }

    // Thử re-login thủ công với stored credentials
    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? '';
      final loginUri = Uri.parse('$baseUrl/auth/login');
      final loginClient = HttpClient();
      final req = await loginClient.postUrl(loginUri);
      req.headers.set('Content-Type', 'application/json');
      req.write(
        jsonEncode({
          'username': credentials['username'],
          'password': credentials['password'],
        }),
      );
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      loginClient.close();

      if (res.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          await storage.setToken(json['data'] as String);
          debugPrint('[SOS-SSE] ✅ Token mới đã lấy — reconnect stream');
          // Token mới đã lưu, thử lại stream
          _retryCount = 0;
          _scheduleReconnect(immediately: true);
          return;
        }
      }
    } catch (e) {
      debugPrint('[SOS-SSE] ❌ Re-login thất bại: $e');
    }

    // Re-login thất bại → về màn login
    debugPrint('[SOS-SSE] Re-login thất bại — về màn login');
    if (Get.isRegistered<EmergencyController>()) {
      Get.find<EmergencyController>().resetSosState();
      Get.delete<EmergencyController>(force: true);
    }
    _disconnect();
    sosList.clear();
    await storage.removeToken();
    await storage.clearCredentials();
    await storage.clearUserInfo();
    Get.offAllNamed('/login');
  }

  // Lấy danh sách SOS
  Future<void> _fetchExistingSos() async {
    try {
      final actives = await _sosRepo.getActiveSosAlerts();
      sosList.assignAll(actives);
    } catch (e) {
      debugPrint('[SOS-SSE] Lỗi tải SOS cũ: $e');
    }
  }
}
