import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:traffic_app/widgets/custom_alert.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../data/repositories/traffic_post_repository.dart';
import '../../../data/services/sos_stream_service.dart';
import '../../../data/services/traffic_post_socket_service.dart';
import '../../../services/storage_service.dart';
import '../widgets/post_bottom_sheet.dart';
import '../widgets/sos_bottom_sheet.dart';
import '../widgets/user_location_marker.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../emergency/controllers/emergency_controller.dart';
import '../../emergency/views/sos_active_screen.dart';
import '../../home/controllers/home_controller.dart';

/// Các kiểu bản đồ hỗ trợ chuyển đổi (Mặc định & Vệ tinh)
enum AppMapType {
  normal,
  satellite,
}

/// Hashtags được đánh dấu trên bản đồ – đồng bộ với CameraController
const List<String> kMapHashtags = [
  'ketxe',
  'giaothong',
  'tainan',
  'ngaplutnuoc',
  'baocaotainan',
  'sos',
];

/// Nhóm các bài viết nằm gần nhau trên bản đồ theo mức zoom hiện tại
class _PostCluster {
  final List<TrafficPostModel> posts;
  final LatLng center;

  _PostCluster({
    required this.posts,
    required this.center,
  });

  TrafficPostModel get primaryPost => posts.first;

  /// Tâm hình học trung bình của toàn bộ bài viết trong cụm
  LatLng get centroid {
    if (posts.isEmpty) return center;
    double sumLat = 0;
    double sumLng = 0;
    int count = 0;
    for (final p in posts) {
      if (p.location != null) {
        sumLat += p.location!.lat;
        sumLng += p.location!.lng;
        count++;
      }
    }
    if (count == 0) return center;
    return LatLng(sumLat / count, sumLng / count);
  }
}

class MapController extends GetxController with GetTickerProviderStateMixin {
  // Controller điều khiển flutter_map engine (tránh xung đột tên với MapController của GetX)
  final fm.MapController mapEngineController = fm.MapController();
  AnimationController? _cameraAnimationController;
  final TextEditingController searchController = TextEditingController();
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  Timer? _searchDebounce;
  CancelToken? _autocompleteCancelToken;

  final _postRepository = TrafficPostRepository();
  final _followRepository = FollowRepository();
  final _storageService = Get.find<StorageService>();

  int? get currentUserId => _storageService.getUserId();

  // Tagged posts (có hashtag khớp kMapHashtags)
  final taggedPosts = <TrafficPostModel>[].obs;

  // Realtime WebSocket service và bộ nhớ đệm
  final TrafficPostSocketService _socketService = TrafficPostSocketService();
  final Map<String, TrafficPostModel> _postsById = {};
  final Map<String, TrafficPostModel> _bufferedPosts = {};
  bool _initialLoadCompleted = false;

  // Tọa độ dự phòng (Hà Nội) chỉ dùng khi chưa lấy được GPS của người dùng
  final LatLng _fallbackCenter = const LatLng(
    21.028511,
    105.804817,
  );
  LatLng get center {
    if (userLocation.value != null) {
      return userLocation.value!;
    }
    if (Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      final lat = dash.userLat.value;
      final lng = dash.userLng.value;
      if (dash.hasUserLocation && lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return _fallbackCenter;
  }

  // Observables for Map State
  var currentMapType = AppMapType.normal.obs;
  final Rxn<LatLng> userLocation = Rxn<LatLng>();
  final markers = <fm.Marker>[].obs;
  final polylines = <fm.Polyline>[].obs;
  var isLoading = false.obs;
  var placeSuggestions = <Map<String, dynamic>>[].obs;

  // Quản lý tách lớp marker để đảm bảo thứ tự Z-index: Post/Cluster -> Search -> UserLocation -> SOS (luôn trên cùng)
  final List<fm.Marker> _postMarkers = [];
  final List<fm.Marker> _sosMarkers = [];
  fm.Marker? _searchResultMarker;
  fm.Marker? _userLocationMarker;
  StreamSubscription<Position>? _positionStreamSub;
  bool _isMapEngineReady = false;
  bool _hasCenteredOnUserInitially = false;
  bool _hasCustomCameraFocus = false;
  bool _isInitLocationRunning = false;
  double _lastClusteredZoom = 14.0;
  static const Distance _geoDistance = Distance();

  double get _safeCurrentZoom {
    try {
      return mapEngineController.camera.zoom;
    } catch (_) {
      return _lastClusteredZoom;
    }
  }

  /// Đồng bộ các lớp marker theo đúng thứ tự ưu tiên hiển thị (SOS luôn nằm trên cùng)
  void _syncCombinedMarkers() {
    markers.assignAll([
      ..._postMarkers,
      ?_searchResultMarker,
      ?_userLocationMarker,
      ..._sosMarkers,
    ]);
  }

  /// Cập nhật tọa độ và tạo lại marker chấm xanh vị trí hiện tại của người dùng
  void _updateUserLocationMarker(LatLng point) {
    userLocation.value = point;
    _userLocationMarker = fm.Marker(
      key: const ValueKey('user_current_location'),
      point: point,
      width: 56,
      height: 56,
      alignment: Alignment.center,
      rotate: true,
      child: UserLocationMarkerWidget(
        size: 56,
        onTap: () => animatedMapMove(point, 16.0),
      ),
    );
    _syncCombinedMarkers();
  }

  /// Lắng nghe luồng thay đổi vị trí khi người dùng di chuyển (>= 10m)
  void _startLocationStream() {
    if (_positionStreamSub != null) return;
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position pos) {
        final point = LatLng(pos.latitude, pos.longitude);
        _updateUserLocationMarker(point);
        if (_isMapEngineReady &&
            !_hasCenteredOnUserInitially &&
            !_hasCustomCameraFocus) {
          _hasCenteredOnUserInitially = true;
          moveToLocation(point, zoom: 15.5);
        }
      },
      onError: (e) {
        debugPrint('MapController position stream error: $e');
      },
    );
  }

  /// Tự động định vị vị trí người dùng khi mở app hoặc mở bản đồ lần đầu
  Future<void> ensureInitialUserLocation({
    bool requestPermissionIfDenied = false,
  }) async {
    if (_isInitLocationRunning) return;
    _isInitLocationRunning = true;

    try {
      // 1. Nếu DashboardController đã lấy sẵn tọa độ hợp lệ, tận dụng ngay để hiển thị tức thì
      if (userLocation.value == null && Get.isRegistered<DashboardController>()) {
        final dash = Get.find<DashboardController>();
        final lat = dash.userLat.value;
        final lng = dash.userLng.value;
        if (dash.hasUserLocation && lat != null && lng != null) {
          final dashPoint = LatLng(lat, lng);
          _updateUserLocationMarker(dashPoint);
          if (_isMapEngineReady &&
              !_hasCenteredOnUserInitially &&
              !_hasCustomCameraFocus) {
            _hasCenteredOnUserInitially = true;
            moveToLocation(dashPoint, zoom: 15.5);
          }
        }
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (requestPermissionIfDenied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // Bắt đầu lắng nghe stream cập nhật vị trí khi người dùng di chuyển
      _startLocationStream();

      // 2. Lấy nhanh vị trí cache gần nhất từ thiết bị để phản hồi tức thì
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final cachedPoint = LatLng(lastKnown.latitude, lastKnown.longitude);
        _updateUserLocationMarker(cachedPoint);
        if (_isMapEngineReady &&
            !_hasCenteredOnUserInitially &&
            !_hasCustomCameraFocus) {
          _hasCenteredOnUserInitially = true;
          moveToLocation(cachedPoint, zoom: 15.5);
        }
      }

      // 3. Lấy tọa độ GPS hiện tại chính xác nhất
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final freshPoint = LatLng(position.latitude, position.longitude);
      final prevPoint = userLocation.value;
      _updateUserLocationMarker(freshPoint);

      if (_isMapEngineReady && !_hasCustomCameraFocus) {
        if (!_hasCenteredOnUserInitially) {
          _hasCenteredOnUserInitially = true;
          moveToLocation(freshPoint, zoom: 15.5);
        } else if (prevPoint != null) {
          final driftMeters = _geoDistance.as(
            LengthUnit.Meter,
            prevPoint,
            freshPoint,
          );
          if (driftMeters > 15.0) {
            animatedMapMove(freshPoint, 15.5);
          }
        }
      }
    } catch (e) {
      debugPrint('MapController ensureInitialUserLocation error: $e');
    } finally {
      _isInitLocationRunning = false;
    }
  }

  /// URL template tương ứng cho TileLayer dựa vào MapType hiện tại (Mặc định & Vệ tinh)
  String get currentTileUrl {
    switch (currentMapType.value) {
      case AppMapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case AppMapType.normal:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  /// URL dự phòng khi OpenStreetMap domain chính bị lỗi mạng hoặc bị DNS nhà mạng chặn
  String? get fallbackTileUrl {
    switch (currentMapType.value) {
      case AppMapType.normal:
        return 'https://tile.openstreetmap.de/{z}/{x}/{y}.png';
      default:
        return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initMapPostsAndSocket();

    // Lắng nghe danh sách SOS theo thời gian thực
    ever(SosStreamService.to.sosList, (_) {
      _buildSosMarkers();
    });

    if (SosStreamService.to.sosList.isNotEmpty) {
      _buildSosMarkers();
    }

    // Lắng nghe trạng thái SOS của chính mình từ EmergencyController
    if (Get.isRegistered<EmergencyController>()) {
      final emergencyCtrl = Get.find<EmergencyController>();
      ever(emergencyCtrl.isSosActive, (isActive) {
        _buildSosMarkers();
        if (isActive == true) {
          centerOnActiveSos(
            isOffsetForSheet: !emergencyCtrl.isSheetMinimized.value,
            zoom: 16.0,
            animated: true,
          );
        }
      });
      ever(emergencyCtrl.activeSosId, (_) => _buildSosMarkers());
      ever(emergencyCtrl.activeSosLat, (_) => _buildSosMarkers());
      ever(emergencyCtrl.activeSosLng, (_) => _buildSosMarkers());

      // Khi người dùng vuốt lên hoặc xuống: tự động căn chỉnh tọa độ focus vào chính giữa phần hiển thị với hiệu ứng lướt mượt mà
      ever(emergencyCtrl.isSheetMinimized, (minimized) {
        if (emergencyCtrl.isSosActive.value) {
          centerOnActiveSos(isOffsetForSheet: !minimized, animated: true);
        }
      });
    }
  }

  /// Di chuyển camera bản đồ đến vị trí chỉ định có hiệu ứng lướt mượt mà (smooth animated camera move)
  void animatedMapMove(
    LatLng destLocation,
    double destZoom, {
    Duration duration = const Duration(milliseconds: 450),
    Curve curve = Curves.easeInOutCubic,
  }) {
    _cameraAnimationController?.dispose();
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: duration,
    );

    final startCenter = mapEngineController.camera.center;
    final startZoom = mapEngineController.camera.zoom;

    final latTween = Tween<double>(begin: startCenter.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: startCenter.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: startZoom, end: destZoom);

    final animation = CurvedAnimation(parent: _cameraAnimationController!, curve: curve);

    _cameraAnimationController!.addListener(() {
      try {
        final nextZoom = zoomTween.evaluate(animation);
        mapEngineController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          nextZoom,
        );
      } catch (e) {
        debugPrint('animatedMapMove error: $e');
      }
    });

    _cameraAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if ((destZoom - _lastClusteredZoom).abs() >= 0.15) {
          _lastClusteredZoom = destZoom;
          _buildPostMarkers(zoom: destZoom);
        }
      }
    });

    _cameraAnimationController!.forward();
  }

  /// Di chuyển camera bản đồ đến tọa độ chỉ định tức thì
  void moveToLocation(LatLng point, {double zoom = 16.0}) {
    try {
      mapEngineController.move(point, zoom);
      if ((zoom - _lastClusteredZoom).abs() >= 0.25) {
        _lastClusteredZoom = zoom;
        _buildPostMarkers(zoom: zoom);
      }
    } catch (e) {
      debugPrint('MapController moveToLocation error: $e');
    }
  }

  /// Căn chỉnh camera focus vào tọa độ SOS:
  /// - isOffsetForSheet = false (khi vuốt xuống): focus vào chính giữa toàn màn hình
  /// - isOffsetForSheet = true (khi vuốt lên): nảy lên trên vào chính giữa khoảng trống bản đồ
  void centerOnActiveSos({
    required bool isOffsetForSheet,
    double? zoom,
    bool animated = true,
  }) {
    if (!Get.isRegistered<EmergencyController>()) return;
    final emCtrl = Get.find<EmergencyController>();
    if (!emCtrl.isSosActive.value) return;
    final lat = emCtrl.activeSosLat.value;
    final lng = emCtrl.activeSosLng.value;
    if (lat == 0.0 || lng == 0.0) return;

    _hasCustomCameraFocus = true;
    final currentZoom = mapEngineController.camera.zoom;
    final targetZoom = zoom ?? (currentZoom < 14.5 ? 15.5 : currentZoom);
    // Khi sheet mở, offset camera xuống phía dưới (lat - 0.0035) để tâm marker nảy lên chính giữa nửa trên bản đồ
    final targetLat = isOffsetForSheet ? (lat - 0.0035) : lat;
    final targetPoint = LatLng(targetLat, lng);

    if (animated) {
      animatedMapMove(targetPoint, targetZoom);
    } else {
      moveToLocation(targetPoint, zoom: targetZoom);
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _autocompleteCancelToken?.cancel();
    _positionStreamSub?.cancel();
    _cameraAnimationController?.dispose();
    _socketService.disconnect();
    searchController.dispose();
    mapEngineController.dispose();
    super.onClose();
  }

  void onMapReady() {
    debugPrint('MapController: flutter_map engine is ready');
    _isMapEngineReady = true;
    _lastClusteredZoom = _safeCurrentZoom;
    _buildPostMarkers(zoom: _lastClusteredZoom);

    final isOnMapTab = Get.isRegistered<HomeController>() &&
        Get.find<HomeController>().currentIndex.value == 1;
    ensureInitialUserLocation(requestPermissionIfDenied: isOnMapTab);
  }

  /// Lắng nghe khi người dùng zoom/pan bản đồ để tính toán lại gom cụm khi mức zoom thay đổi
  void onMapPositionChanged(fm.MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _hasCustomCameraFocus = true;
    }
    if ((camera.zoom - _lastClusteredZoom).abs() >= 0.25) {
      _lastClusteredZoom = camera.zoom;
      _buildPostMarkers(zoom: camera.zoom);
    }
  }

  void fetchSuggestions(String input) {
    _searchDebounce?.cancel();
    _autocompleteCancelToken?.cancel();

    if (input.trim().isEmpty) {
      placeSuggestions.clear();
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final cancelToken = CancelToken();
      _autocompleteCancelToken = cancelToken;

      try {
        final response = await _dio.get(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json',
          queryParameters: {
            'input': input,
            'key': _apiKey,
            'components': 'country:vn', // Limit to Vietnam
          },
          cancelToken: cancelToken,
        );
        if (response.statusCode == 200) {
          final predictions = response.data['predictions'] as List;
          placeSuggestions.value = predictions.cast<Map<String, dynamic>>();
        }
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) return;
        debugPrint('Error fetching suggestions: $e');
      } catch (e) {
        debugPrint('Error fetching suggestions: $e');
      }
    });
  }

  Future<void> selectSuggestion(Map<String, dynamic> suggestion) async {
    _searchDebounce?.cancel();
    _autocompleteCancelToken?.cancel();
    searchController.text = suggestion['description'];
    placeSuggestions.clear();
    await searchLocation(suggestion['description']);
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty) return;

    try {
      isLoading.value = true;
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng target = LatLng(location.latitude, location.longitude);

        _hasCustomCameraFocus = true;
        moveToLocation(target, zoom: 16.0);

        _searchResultMarker = fm.Marker(
          key: const ValueKey('search_result'),
          point: target,
          width: 44,
          height: 44,
          alignment: Alignment.topCenter,
          rotate: true,
          child: Tooltip(
            message: query,
            child: const Icon(
              Icons.location_pin,
              color: Colors.purple,
              size: 40,
            ),
          ),
        );
        _syncCombinedMarkers();
      } else {
        CustomAlert.showWarning('map_location_not_found'.tr);
      }
    } catch (e) {
      CustomAlert.showError('${'map_cannot_search'.tr}: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleMapType() {
    currentMapType.value = currentMapType.value == AppMapType.normal
        ? AppMapType.satellite
        : AppMapType.normal;
  }

  Future<void> goToMyLocation() async {
    try {
      isLoading.value = true;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        CustomAlert.showError('map_location_service_disabled'.tr);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          CustomAlert.showError('map_location_permission_denied'.tr);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        CustomAlert.showError('map_location_permission_denied_forever'.tr);
        return;
      }

      _startLocationStream();

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final myPoint = LatLng(position.latitude, position.longitude);
      _updateUserLocationMarker(myPoint);
      _hasCenteredOnUserInitially = true;
      animatedMapMove(myPoint, 15.5);
    } catch (e) {
      CustomAlert.showError('${'cannot_get_location'.tr}: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Khởi tạo luồng nạp bài viết và kết nối STOMP an toàn không sót bài
  Future<void> _initMapPostsAndSocket() async {
    // 1. Kết nối WebSocket trước để không bỏ lỡ bài viết nào ở giữa
    await _connectSocket();

    // 2. Tải bài viết ban đầu qua REST API
    await loadTaggedPosts();
  }

  /// Kết nối tới STOMP WebSocket server
  Future<void> _connectSocket() async {
    final token = _storageService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[MapController] Chưa có JWT token, bỏ qua kết nối STOMP');
      return;
    }

    final wsUrl = TrafficPostSocketService.resolveWebSocketUrl();

    try {
      await _socketService.connect(
        webSocketUrl: wsUrl,
        jwt: token,
        onNewPost: (post) {
          if (!_initialLoadCompleted) {
            // Buffer event trong lúc REST ban đầu đang load
            if (post.id != null) {
              _bufferedPosts[post.id!] = post;
            }
            return;
          }
          upsertPostAndMarker(post);
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().onRealtimePostReceived(post);
          }
        },
        onReconnect: () async {
          debugPrint('[MapController] 🔄 Reconnected! Resync bài viết từ REST...');
          await _resyncPostsFromRest();
        },
        onError: (err) {
          debugPrint('[MapController] STOMP Socket error: $err');
        },
      );
    } catch (e) {
      debugPrint('[MapController] Lỗi khởi tạo WebSocket: $e');
    }
  }

  /// Kiểm tra bài viết có đủ điều kiện hiển thị trên bản đồ không
  bool _isEligibleForMap(TrafficPostModel post) {
    if (!post.isVisible) return false;
    final loc = post.location;
    if (loc == null) return false;

    final tags = post.hashtags?.map((t) => t.toLowerCase()).toList() ?? [];
    if (tags.any((t) => kMapHashtags.contains(t))) return true;

    if (post.type != null && post.type!.isNotEmpty) {
      final t = post.type!.toLowerCase();
      if (t == 'accident' ||
          t == 'traffic' ||
          t == 'sos' ||
          t == 'hazard' ||
          t == 'congestion') {
        return true;
      }
    }

    // Nếu không có hashtag nhưng có tọa độ và content thì vẫn hiển thị
    return tags.isEmpty && post.content != null && post.content!.isNotEmpty;
  }

  /// Load tất cả bài viết từ REST API, merge với buffer và render marker
  Future<void> loadTaggedPosts() async {
    try {
      final posts = await _postRepository.getPosts(
        page: 0,
        size: 50,
      );

      // Thêm bài viết từ REST
      for (final post in posts) {
        if (post.id != null && _isEligibleForMap(post)) {
          _postsById[post.id!] = post;
        }
      }

      // Thêm các bài buffered nhận được trong lúc REST đang tải
      for (final post in _bufferedPosts.values) {
        if (post.id != null && _isEligibleForMap(post)) {
          _postsById[post.id!] = post;
        }
      }
      _bufferedPosts.clear();

      _initialLoadCompleted = true;
      taggedPosts.value = _postsById.values.toList();
      _buildPostMarkers();
    } catch (e) {
      debugPrint('MapController loadTaggedPosts error: $e');
      _initialLoadCompleted = true;
    }
  }

  /// Đồng bộ bù dữ liệu từ REST sau khi reconnect WebSocket thành công
  Future<void> _resyncPostsFromRest() async {
    try {
      final posts = await _postRepository.getPosts(
        page: 0,
        size: 50,
      );

      bool hasNew = false;
      for (final post in posts) {
        if (post.id != null &&
            !_postsById.containsKey(post.id) &&
            _isEligibleForMap(post)) {
          _postsById[post.id!] = post;
          taggedPosts.add(post);
          hasNew = true;
        }
      }

      if (hasNew) {
        _buildPostMarkers();
        debugPrint(
          '[MapController] ✅ Đồng bộ REST bù hoàn tất, đã thêm các bài mới bị lỡ',
        );
      }
    } catch (e) {
      debugPrint('[MapController] Lỗi đồng bộ bù REST: $e');
    }
  }

  /// Thêm marker an toàn khi nhận tin realtime (dedupe bằng post.id)
  void upsertPostAndMarker(TrafficPostModel post) {
    if (post.id != null && !post.isVisible) {
      syncPostDeleted(post.id!);
      return;
    }

    final location = post.location;
    if (location == null) {
      return;
    }

    if (post.id == null || _postsById.containsKey(post.id)) {
      return;
    }

    if (!_isEligibleForMap(post)) {
      return;
    }

    _postsById[post.id!] = post;
    taggedPosts.add(post);
    _buildPostMarkers();
    debugPrint('[MapController] 📍 Đã thêm & gom cụm marker realtime cho post: ${post.id}');
  }

  /// Trích xuất tag khớp đầu tiên và nhãn hiển thị của bài viết
  (String firstTag, String displayTag, Color tagColor) _resolvePostTagInfo(
    TrafficPostModel post,
  ) {
    final matchingTags = (post.hashtags ?? [])
        .map((t) => t.toLowerCase().replaceAll('#', '').trim())
        .where((t) => kMapHashtags.contains(t))
        .toList();
    final firstTag = matchingTags.isNotEmpty ? matchingTags.first : '';
    final displayTag = firstTag.isNotEmpty
        ? '#$firstTag'
        : ((post.hashtags?.isNotEmpty ?? false)
            ? '#${post.hashtags!.first.replaceAll('#', '')}'
            : (post.type != null && post.type!.isNotEmpty
                ? '#${post.type}'
                : ''));
    final tagColor = _colorForTag(firstTag);
    return (firstTag, displayTag, tagColor);
  }

  /// Điểm ưu tiên của bài viết (SOS > Tai nạn > Báo cáo tai nạn > Kẹt xe > Ngập nước > Giao thông)
  int _priorityForPost(TrafficPostModel post) {
    final (firstTag, _, _) = _resolvePostTagInfo(post);
    switch (firstTag) {
      case 'sos':
        return 60;
      case 'tainan':
        return 50;
      case 'baocaotainan':
        return 40;
      case 'ketxe':
        return 30;
      case 'ngaplutnuoc':
        return 20;
      case 'giaothong':
      default:
        return 10;
    }
  }

  /// Bán kính gom cụm (mét) theo mức zoom hiện tại (tương ứng ~58px trên màn hình)
  double _clusterRadiusMetersForZoom(double zoom) {
    return (58.0 * 146000.0) / math.pow(2.0, zoom);
  }

  /// Dựng marker đơn lẻ cho 1 bài viết (neo chuẩn mũi ghim Alignment.topCenter và tự xoay theo mắt nhìn)
  fm.Marker? _createMarkerForPost(
    TrafficPostModel post, {
    bool showLabel = true,
  }) {
    final loc = post.location;
    if (loc == null) return null;

    final (_, displayTag, tagColor) = _resolvePostTagInfo(post);
    final shouldShowTag = showLabel && displayTag.isNotEmpty;

    return fm.Marker(
      key: ValueKey('post_${post.id}'),
      point: LatLng(loc.lat, loc.lng),
      width: 92,
      height: shouldShowTag ? 64 : 42,
      alignment: Alignment.topCenter,
      rotate: true,
      child: GestureDetector(
        onTap: () => _showPostBottomSheet(post),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (shouldShowTag)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  displayTag,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Icon(
              Icons.location_on,
              color: tagColor,
              size: 36,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dựng Cluster Marker khi có nhiều bài viết nằm gần nhau hoặc trùng vị trí
  fm.Marker _createClusterMarker(
    _PostCluster cluster, {
    bool showLabel = true,
  }) {
    final primary = cluster.primaryPost;
    final count = cluster.posts.length;
    final (_, displayTag, tagColor) = _resolvePostTagInfo(primary);
    final shouldShowTag = showLabel && displayTag.isNotEmpty;
    final countText = count > 99 ? '99+' : '$count';

    return fm.Marker(
      key: ValueKey('cluster_${primary.id}_$count'),
      point: cluster.centroid,
      width: 112,
      height: shouldShowTag ? 70 : 48,
      alignment: Alignment.topCenter,
      rotate: true,
      child: GestureDetector(
        onTap: () => _onClusterTapped(cluster),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (shouldShowTag)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tagColor.withValues(alpha: 0.45),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayTag,
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${count - 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: 46,
              height: 40,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.location_on,
                    color: tagColor,
                    size: 38,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.38),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        countText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xử lý khi người dùng bấm vào 1 Cluster Marker:
  /// - Nếu đang zoom xa (< 16.5) và các điểm cách nhau > 25m -> Tự động zoom in tách cụm
  /// - Nếu đã zoom gần (>= 16.5) hoặc các điểm trùng vị trí (<= 25m) -> Mở BottomSheet xem toàn bộ bài viết trong cụm
  void _onClusterTapped(_PostCluster cluster) {
    final currentZoom = _safeCurrentZoom;
    final center = cluster.centroid;

    double maxSpreadMeters = 0;
    for (final p in cluster.posts) {
      if (p.location != null) {
        final d = _geoDistance.as(
          LengthUnit.Meter,
          center,
          LatLng(p.location!.lat, p.location!.lng),
        );
        if (d > maxSpreadMeters) {
          maxSpreadMeters = d;
        }
      }
    }

    if (currentZoom < 16.5 && maxSpreadMeters > 25.0) {
      final targetZoom = (currentZoom + 2.0).clamp(14.5, 17.2);
      animatedMapMove(center, targetZoom);
    } else {
      _showPostsBottomSheet(cluster.posts);
    }
  }

  /// Dựng toàn bộ markers từ danh sách taggedPosts có gom cụm theo mức zoom và phân tầng ưu tiên
  void _buildPostMarkers({double? zoom}) {
    final currentZoom = zoom ?? _safeCurrentZoom;
    final radiusMeters = _clusterRadiusMetersForZoom(currentZoom);
    final showLabel = currentZoom >= 12.5;

    // 1. Sắp xếp bài viết theo độ ưu tiên giảm dần, sau đó theo thời gian mới nhất giảm dần
    final validPosts = taggedPosts.where((p) => p.location != null).toList()
      ..sort((a, b) {
        final prioCmp = _priorityForPost(b).compareTo(_priorityForPost(a));
        if (prioCmp != 0) return prioCmp;
        final timeA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA);
      });

    // 2. Gom cụm các bài viết nằm gần nhau trong bán kính radiusMeters
    final List<_PostCluster> clusters = [];
    for (final post in validPosts) {
      final point = LatLng(post.location!.lat, post.location!.lng);
      _PostCluster? matchedCluster;
      double minDistance = double.infinity;

      for (final cluster in clusters) {
        final dist = _geoDistance.as(LengthUnit.Meter, cluster.center, point);
        if (dist <= radiusMeters && dist < minDistance) {
          minDistance = dist;
          matchedCluster = cluster;
        }
      }

      if (matchedCluster != null) {
        matchedCluster.posts.add(post);
      } else {
        clusters.add(_PostCluster(posts: [post], center: point));
      }
    }

    // 3. Sắp xếp thứ tự vẽ (Z-order từ dưới lên trên):
    // Marker đơn có độ ưu tiên thấp vẽ trước -> Marker đơn ưu tiên cao -> Cluster Marker vẽ trên cùng
    clusters.sort((a, b) {
      final aIsCluster = a.posts.length > 1 ? 1 : 0;
      final bIsCluster = b.posts.length > 1 ? 1 : 0;
      if (aIsCluster != bIsCluster) {
        return aIsCluster.compareTo(bIsCluster);
      }
      return _priorityForPost(a.primaryPost)
          .compareTo(_priorityForPost(b.primaryPost));
    });

    _postMarkers.clear();
    for (final cluster in clusters) {
      if (cluster.posts.length == 1) {
        final marker = _createMarkerForPost(
          cluster.posts.first,
          showLabel: showLabel,
        );
        if (marker != null) {
          _postMarkers.add(marker);
        }
      } else {
        _postMarkers.add(
          _createClusterMarker(
            cluster,
            showLabel: currentZoom >= 12.0,
          ),
        );
      }
    }

    _syncCombinedMarkers();
  }

  Color _colorForTag(String tag) {
    switch (tag) {
      case 'ketxe':
        return Colors.red;
      case 'tainan':
        return Colors.deepOrange;
      case 'ngaplutnuoc':
        return Colors.cyan;
      case 'baocaotainan':
        return Colors.amber;
      case 'sos':
        return Colors.pinkAccent;
      case 'giaothong':
      default:
        return Colors.purple;
    }
  }

  TrafficPostModel _resolveFreshPost(TrafficPostModel post) {
    if (post.id != null && _postsById.containsKey(post.id)) {
      return _postsById[post.id!]!;
    }
    return post;
  }

  void _showPostBottomSheet(TrafficPostModel initialPost) {
    PostBottomSheet.show(
      post: _resolveFreshPost(initialPost),
      currentUserId: currentUserId,
      onLike: _toggleLike,
      onFollow: _toggleFollow,
      onReport: _reportPost,
    );
  }

  void _showPostsBottomSheet(List<TrafficPostModel> posts) {
    PostBottomSheet.show(
      posts: posts.map(_resolveFreshPost).toList(),
      currentUserId: currentUserId,
      onLike: _toggleLike,
      onFollow: _toggleFollow,
      onReport: _reportPost,
    );
  }

  /// Di chuyển camera bản đồ đến vị trí của bài viết được chọn từ Trang chủ
  void focusOnPost(TrafficPostModel post) {
    final loc = post.location;
    if (loc == null) return;

    _hasCustomCameraFocus = true;

    // Đảm bảo bài viết có marker trên bản đồ
    if (post.id != null && !_postsById.containsKey(post.id)) {
      _postsById[post.id!] = post;
      taggedPosts.add(post);
      _buildPostMarkers();
    }

    final target = LatLng(loc.lat, loc.lng);
    Future.delayed(const Duration(milliseconds: 180), () {
      animatedMapMove(target, 16.5);
    });
  }

  /// Đồng bộ trạng thái Like từ Dashboard sang Map
  void syncPostLikeState(String postId, bool isLiked, int likes) {
    final existing = _postsById[postId];
    if (existing != null) {
      final updated = existing.copyWith(isLiked: isLiked, likes: likes);
      _syncToTaggedPosts(updated);
    }
  }

  /// Đồng bộ trạng thái Follow từ Dashboard/Profile sang Map
  void syncUserFollowState(String userId, bool isFollowed) {
    for (int i = 0; i < taggedPosts.length; i++) {
      final p = taggedPosts[i];
      if (p.userId == userId) {
        final updated = p.copyWith(isFollowedByCurrentUser: isFollowed);
        taggedPosts[i] = updated;
        if (updated.id != null) {
          _postsById[updated.id!] = updated;
        }
      }
    }
  }

  Future<void> _toggleLike(Rx<TrafficPostModel> postRx) async {
    final p = postRx.value;
    if (p.id == null) return;
    final wasLiked = p.isLiked ?? false;
    final prevLikes = p.likes ?? 0;
    final newLiked = !wasLiked;
    final newLikes = wasLiked ? prevLikes - 1 : prevLikes + 1;

    postRx.value = p.copyWith(
      isLiked: newLiked,
      likes: newLikes,
    );
    _syncToTaggedPosts(postRx.value);
    if (Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      dash.likedState(p.id!).value = newLiked;
      dash.likeCount(p.id!).value = newLikes;
    }

    try {
      await _postRepository.likePost(p.id!);
    } catch (_) {
      postRx.value = p.copyWith(isLiked: wasLiked, likes: prevLikes);
      _syncToTaggedPosts(postRx.value);
      if (Get.isRegistered<DashboardController>()) {
        final dash = Get.find<DashboardController>();
        dash.likedState(p.id!).value = wasLiked;
        dash.likeCount(p.id!).value = prevLikes;
      }
    }
  }

  Future<void> _toggleFollow(Rx<TrafficPostModel> postRx) async {
    final p = postRx.value;
    final userId = int.tryParse(p.userId ?? '');
    if (userId == null) return;
    final wasFollowing = p.isFollowedByCurrentUser ?? false;
    final newFollowing = !wasFollowing;
    postRx.value = p.copyWith(isFollowedByCurrentUser: newFollowing);
    syncUserFollowState(p.userId!, newFollowing);
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().syncFollowFromExternal(
        p.userId!,
        newFollowing,
      );
    }

    try {
      await _followRepository.followUser(userId);
    } catch (_) {
      postRx.value = p.copyWith(isFollowedByCurrentUser: wasFollowing);
      syncUserFollowState(p.userId!, wasFollowing);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().syncFollowFromExternal(
          p.userId!,
          wasFollowing,
        );
      }
    }
  }

  void _reportPost(TrafficPostModel post) {
    if (post.id == null) return;

    _postRepository
        .reportPost(postId: post.id!, reason: 'dashboard_report_reason_inappropriate'.tr)
        .then((_) => CustomAlert.showSuccess('dashboard_report_success'.tr))
        .catchError((e) => CustomAlert.showError(e.toString()));
  }

  /// Đồng bộ thay đổi bài viết vào danh sách taggedPosts
  void _syncToTaggedPosts(TrafficPostModel updated) {
    final idx = taggedPosts.indexWhere((p) => p.id == updated.id);
    if (idx != -1) taggedPosts[idx] = updated;
    if (updated.id != null) {
      _postsById[updated.id!] = updated;
    }
  }

  /// Đồng bộ nội dung bài viết sau khi người dùng chỉnh sửa
  void syncPostContentUpdated(String postId, String newContent) {
    final existing = _postsById[postId];
    if (existing != null) {
      final updated = existing.copyWith(content: newContent);
      _syncToTaggedPosts(updated);
    } else {
      final idx = taggedPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final updated = taggedPosts[idx].copyWith(content: newContent);
        taggedPosts[idx] = updated;
        _postsById[postId] = updated;
      }
    }
  }

  /// Đồng bộ xóa bài viết khỏi bản đồ
  void syncPostDeleted(String postId) {
    _postsById.remove(postId);
    _bufferedPosts.remove(postId);
    final beforeLen = taggedPosts.length;
    taggedPosts.removeWhere((p) => p.id == postId);
    if (taggedPosts.length != beforeLen) {
      _buildPostMarkers();
    }
  }

  void _buildSosMarkers() {
    // 1. Dọn dẹp danh sách marker SOS cũ
    _sosMarkers.clear();

    // 2. Kiểm tra nếu chính người dùng đang phát tín hiệu SOS -> Hiển thị Radar Marker sóng tỏa
    String myActiveId = '';
    if (Get.isRegistered<EmergencyController>()) {
      final emergencyCtrl = Get.find<EmergencyController>();
      myActiveId = emergencyCtrl.activeSosId.value;

      if (emergencyCtrl.isSosActive.value &&
          emergencyCtrl.activeSosLat.value != 0.0 &&
          emergencyCtrl.activeSosLng.value != 0.0) {
        _sosMarkers.add(
          fm.Marker(
            key: const ValueKey('my_active_sos_radar'),
            point: LatLng(
              emergencyCtrl.activeSosLat.value,
              emergencyCtrl.activeSosLng.value,
            ),
            width: 140,
            height: 140,
            alignment: Alignment.center,
            rotate: true,
            child: SosRadarMarkerWidget(
              size: 140,
              onTap: () {
                // Chạm vào radar trên map mở lại sheet
                emergencyCtrl.isSheetMinimized.value = false;
              },
            ),
          ),
        );
      }
    }

    // 3. Lấy dữ liệu từ Service (dành cho các SOS khác trong khu vực)
    final sosList = SosStreamService.to.sosList;

    for (final sos in sosList) {
      if (sos.latitude == null || sos.longitude == null) continue;
      // Bỏ qua nếu là SOS của chính mình vì đã được vẽ radar marker ở trên
      if (myActiveId.isNotEmpty && sos.sosId == myActiveId) continue;

      _sosMarkers.add(
        fm.Marker(
          key: ValueKey('sos_${sos.sosId}'),
          point: LatLng(sos.latitude!, sos.longitude!),
          width: 140,
          height: 140,
          alignment: Alignment.center,
          rotate: true,
          child: SosRadarMarkerWidget(
            size: 140,
            onTap: () => SosBottomSheet.show(sos: sos),
          ),
        ),
      );
    }

    _syncCombinedMarkers();
  }
}
