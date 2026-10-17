import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:traffic_app/widgets/custom_alert.dart';

import '../../../data/models/location_model.dart';
import '../../../data/models/traffic_post_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../data/repositories/traffic_post_repository.dart';
import '../../../data/services/sos_stream_service.dart';
import '../../../data/services/traffic_post_socket_service.dart';
import '../../../services/storage_service.dart';
import '../widgets/post_bottom_sheet.dart';
import '../widgets/sos_bottom_sheet.dart';
import '../../emergency/controllers/emergency_controller.dart';
import '../../emergency/views/sos_active_screen.dart';

/// Các kiểu bản đồ hỗ trợ chuyển đổi
enum AppMapType {
  normal,
  satellite,
  terrain,
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

class MapController extends GetxController with GetTickerProviderStateMixin {
  // Controller điều khiển flutter_map engine (tránh xung đột tên với MapController của GetX)
  final fm.MapController mapEngineController = fm.MapController();
  AnimationController? _cameraAnimationController;
  final TextEditingController searchController = TextEditingController();
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

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

  // Tọa độ khởi tạo hợp lệ (Hà Nội) - Giá trị cố định sẵn sàng ngay lập tức
  final LatLng _center = const LatLng(
    21.028511,
    105.804817,
  );
  LatLng get center => _center;

  // Observables for Map State
  var currentMapType = AppMapType.normal.obs;
  var isTrafficEnabled = false.obs;
  final markers = <fm.Marker>[].obs;
  final polylines = <fm.Polyline>[].obs;
  var isLoading = false.obs;
  var placeSuggestions = <Map<String, dynamic>>[].obs;

  /// URL template tương ứng cho TileLayer dựa vào MapType hiện tại
  String get currentTileUrl {
    switch (currentMapType.value) {
      case AppMapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case AppMapType.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
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
    _checkLocationPermission();

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
        mapEngineController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      } catch (e) {
        debugPrint('animatedMapMove error: $e');
      }
    });

    _cameraAnimationController!.forward();
  }

  /// Di chuyển camera bản đồ đến tọa độ chỉ định tức thì
  void moveToLocation(LatLng point, {double zoom = 16.0}) {
    try {
      mapEngineController.move(point, zoom);
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
    _cameraAnimationController?.dispose();
    _socketService.disconnect();
    searchController.dispose();
    mapEngineController.dispose();
    super.onClose();
  }

  void onMapReady() {
    debugPrint('MapController: flutter_map engine is ready');
  }

  Future<void> fetchSuggestions(String input) async {
    if (input.isEmpty) {
      placeSuggestions.clear();
      return;
    }

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'components': 'country:vn', // Limit to Vietnam
        },
      );
      if (response.statusCode == 200) {
        final predictions = response.data['predictions'] as List;
        placeSuggestions.value = predictions.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  Future<void> selectSuggestion(Map<String, dynamic> suggestion) async {
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

        mapEngineController.move(target, 16.0);

        markers.removeWhere(
          (m) =>
              m.key is ValueKey &&
              (m.key as ValueKey).value == 'search_result',
        );
        markers.add(
          fm.Marker(
            key: const ValueKey('search_result'),
            point: target,
            width: 44,
            height: 44,
            child: Tooltip(
              message: query,
              child: const Icon(
                Icons.location_pin,
                color: Colors.purple,
                size: 40,
              ),
            ),
          ),
        );
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
    final types = [
      AppMapType.normal,
      AppMapType.satellite,
      AppMapType.terrain,
    ];
    final currentIndex = types.indexOf(currentMapType.value);
    currentMapType.value = types[(currentIndex + 1) % types.length];
  }

  void toggleTraffic() {
    isTrafficEnabled.value = !isTrafficEnabled.value;
  }

  Future<void> _checkLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      var status = await Permission.location.status;
      if (!status.isGranted) {
        await Permission.location.request();
      }
    } catch (e) {
      debugPrint('MapController _checkLocationPermission error: $e');
    }
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

      Position position = await Geolocator.getCurrentPosition();
      mapEngineController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
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
        location: '',
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
        location: '',
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

          final marker = _createMarkerForPost(post);
          if (marker != null) {
            markers.add(marker);
          }
          hasNew = true;
        }
      }

      if (hasNew) {
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

    final newMarker = _createMarkerForPost(post);
    if (newMarker != null) {
      // Đảm bảo không trùng key
      markers.removeWhere((m) => m.key == newMarker.key);
      markers.add(newMarker);
      debugPrint('[MapController] 📍 Đã thêm marker realtime cho post: ${post.id}');
    }
  }

  /// Dựng marker cho 1 bài viết
  fm.Marker? _createMarkerForPost(TrafficPostModel post) {
    final loc = post.location;
    if (loc == null) return null;

    // Màu marker theo hashtag đầu tiên khớp
    final matchingTags = (post.hashtags ?? [])
        .map((t) => t.toLowerCase())
        .where((t) => kMapHashtags.contains(t))
        .toList();
    final firstTag = matchingTags.isNotEmpty ? matchingTags.first : '';
    final displayTag = firstTag.isNotEmpty
        ? '#$firstTag'
        : ((post.hashtags?.isNotEmpty ?? false)
            ? '#${post.hashtags!.first}'
            : (post.type != null && post.type!.isNotEmpty ? '#${post.type}' : ''));
    final tagColor = _colorForTag(firstTag);

    return fm.Marker(
      key: ValueKey('post_${post.id}'),
      point: LatLng(loc.lat, loc.lng),
      width: 85,
      height: 65,
      child: GestureDetector(
        onTap: () => _showPostBottomSheet(post),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (displayTag.isNotEmpty)
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

  /// Dựng toàn bộ markers từ danh sách taggedPosts
  void _buildPostMarkers() {
    // Xóa marker bài viết cũ, giữ search_result và sos nếu có
    markers.removeWhere(
      (m) =>
          m.key is ValueKey &&
          (m.key as ValueKey).value.toString().startsWith('post_'),
    );

    for (final post in taggedPosts) {
      final marker = _createMarkerForPost(post);
      if (marker != null) {
        markers.add(marker);
      }
    }
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

  void _showPostBottomSheet(TrafficPostModel initialPost) {
    PostBottomSheet.show(
      post: initialPost,
      currentUserId: currentUserId,
      onLike: _toggleLike,
      onFollow: _toggleFollow,
      onReport: _reportPost,
    );
  }

  Future<void> _toggleLike(Rx<TrafficPostModel> postRx) async {
    final p = postRx.value;
    if (p.id == null) return;
    final wasLiked = p.isLiked ?? false;
    final prevLikes = p.likes ?? 0;
    postRx.value = p.copyWith(
      isLiked: !wasLiked,
      likes: wasLiked ? prevLikes - 1 : prevLikes + 1,
    );
    _syncToTaggedPosts(postRx.value);

    try {
      await _postRepository.likePost(p.id!);
    } catch (_) {
      postRx.value = p.copyWith(isLiked: wasLiked, likes: prevLikes);
      _syncToTaggedPosts(postRx.value);
    }
  }

  Future<void> _toggleFollow(Rx<TrafficPostModel> postRx) async {
    final p = postRx.value;
    final userId = int.tryParse(p.userId ?? '');
    if (userId == null) return;
    final wasFollowing = p.isFollowedByCurrentUser ?? false;
    postRx.value = p.copyWith(isFollowedByCurrentUser: !wasFollowing);
    _syncToTaggedPosts(postRx.value);

    try {
      await _followRepository.followUser(userId);
    } catch (_) {
      postRx.value = p.copyWith(isFollowedByCurrentUser: wasFollowing);
      _syncToTaggedPosts(postRx.value);
    }
  }

  void _reportPost(TrafficPostModel post) {
    if (post.id == null) return;

    _postRepository
        .reportPost(postId: post.id!, reason: 'Nội dung không phù hợp')
        .then((_) => CustomAlert.showSuccess('Đã báo cáo bài viết'))
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

  void _buildSosMarkers() {
    // 1. Dọn dẹp các marker SOS cũ (giữ lại marker bài viết 'post_' và 'search_result')
    markers.removeWhere(
      (m) =>
          m.key is ValueKey &&
          ((m.key as ValueKey).value.toString().startsWith('sos_') ||
           (m.key as ValueKey).value.toString() == 'my_active_sos_radar'),
    );

    // 2. Kiểm tra nếu chính người dùng đang phát tín hiệu SOS -> Hiển thị Radar Marker sóng tỏa
    String myActiveId = '';
    if (Get.isRegistered<EmergencyController>()) {
      final emergencyCtrl = Get.find<EmergencyController>();
      myActiveId = emergencyCtrl.activeSosId.value;

      if (emergencyCtrl.isSosActive.value &&
          emergencyCtrl.activeSosLat.value != 0.0 &&
          emergencyCtrl.activeSosLng.value != 0.0) {
        markers.add(
          fm.Marker(
            key: const ValueKey('my_active_sos_radar'),
            point: LatLng(
              emergencyCtrl.activeSosLat.value,
              emergencyCtrl.activeSosLng.value,
            ),
            width: 140,
            height: 140,
            alignment: Alignment.center,
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

      markers.add(
        fm.Marker(
          key: ValueKey('sos_${sos.sosId}'),
          point: LatLng(sos.latitude!, sos.longitude!),
          width: 140,
          height: 140,
          alignment: Alignment.center,
          child: SosRadarMarkerWidget(
            size: 140,
            onTap: () => SosBottomSheet.show(sos: sos),
          ),
        ),
      );
    }
  }
}
