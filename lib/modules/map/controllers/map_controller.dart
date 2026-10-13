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

import '../../../config/demo_config.dart';
import '../../../data/models/traffic_post_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../data/repositories/traffic_post_repository.dart';
import '../../../data/services/sos_stream_service.dart';
import '../../../services/storage_service.dart';
import '../widgets/post_bottom_sheet.dart';
import '../widgets/sos_bottom_sheet.dart';

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

class MapController extends GetxController {
  // Controller điều khiển flutter_map engine (tránh xung đột tên với MapController của GetX)
  final fm.MapController mapEngineController = fm.MapController();
  final TextEditingController searchController = TextEditingController();
  final Dio _dio = Dio();
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  final _postRepository = TrafficPostRepository();
  final _followRepository = FollowRepository();
  final _storageService = Get.find<StorageService>();

  int? get currentUserId => _storageService.getUserId();

  // Tagged posts (có hashtag khớp kMapHashtags)
  final taggedPosts = <TrafficPostModel>[].obs;

  Timer? _markerRefreshTimer;

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
    // Khởi tạo bài viết mẫu để hiển thị ngay lập tức các marker lên bản đồ
    taggedPosts.value = _getSampleTaggedPosts();
    _buildPostMarkers();

    if (DemoConfig.isDemoMode) {
      debugPrint('[MapController] 📍 Kích hoạt vị trí cố định trên bản đồ Web Demo');
      polylines.clear();
      updateSimulatedUserMarker(DemoConfig.defaultCenter);
    } else {
      loadTaggedPosts();
      _markerRefreshTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => loadTaggedPosts(),
      );
      _addDummyPolyline();
      _checkLocationPermission();
    }

    // Lắng nghe danh sách SOS theo thời gian thực
    ever(SosStreamService.to.sosList, (_) {
      _buildSosMarkers();
    });

    if (SosStreamService.to.sosList.isNotEmpty) {
      _buildSosMarkers();
    }
  }

  @override
  void onClose() {
    _markerRefreshTimer?.cancel();
    searchController.dispose();
    mapEngineController.dispose();
    super.onClose();
  }

  void onMapReady() {
    debugPrint('MapController: flutter_map engine is ready');
    if (DemoConfig.isDemoMode) {
      updateSimulatedUserMarker(DemoConfig.currentSimulatedPosition);
    }
  }

  /// Danh sách bài viết mẫu đa dạng hashtag để kiểm tra hiển thị Marker trên bản đồ
  List<TrafficPostModel> _getSampleTaggedPosts() {
    return DemoConfig.getInitialSamplePosts();
  }


  /// Cập nhật vị trí phương tiện mô phỏng di chuyển theo thời gian thực
  void updateSimulatedUserMarker(LatLng position) {
    markers.removeWhere(
      (m) =>
          m.key is ValueKey &&
          (m.key as ValueKey).value == 'simulated_user_location',
    );

    markers.add(
      fm.Marker(
        key: const ValueKey('simulated_user_location'),
        point: position,
        width: 54,
        height: 54,
        child: Tooltip(
          message: 'Vị trí của bạn (Cố định)',
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2979FF).withOpacity(0.25),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1565C0),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.55),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bổ sung bài viết giao thông giả lập phát sinh định kỳ vào bản đồ
  void addDynamicPost(TrafficPostModel post) {
    if (!taggedPosts.any((p) => p.id == post.id)) {
      taggedPosts.insert(0, post);
      _buildPostMarkers();
    }
  }

  /// Zoom In bằng nút click chuột
  void zoomIn() {
    final currentZoom = mapEngineController.camera.zoom;
    mapEngineController.move(
      mapEngineController.camera.center,
      (currentZoom + 1.0).clamp(3.0, 19.0),
    );
  }

  /// Zoom Out bằng nút click chuột
  void zoomOut() {
    final currentZoom = mapEngineController.camera.zoom;
    mapEngineController.move(
      mapEngineController.camera.center,
      (currentZoom - 1.0).clamp(3.0, 19.0),
    );
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
    // Không yêu cầu popup cấp quyền GPS của trình duyệt trên Web Demo
    if (DemoConfig.isDemoMode) {
      debugPrint('[MapController] Demo Mode: Không yêu cầu popup cấp quyền GPS của trình duyệt');
      return;
    }

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
    // Ở Web Demo: Di chuyển đến vị trí mô phỏng thay vì xin quyền GPS trình duyệt
    if (DemoConfig.isDemoMode) {
      final target = DemoConfig.currentSimulatedPosition;
      mapEngineController.move(target, 16.0);
      CustomAlert.showSuccess('Đang hiển thị vị trí cố định (Web Demo)');
      return;
    }

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

  /// Load tất cả bài viết, lọc theo hashtag, tạo marker
  Future<void> loadTaggedPosts() async {
    try {
      final posts = await _postRepository.getPosts(
        location: '',
        page: 0,
        size: 50,
      );

      // Lọc bài có hashtag nằm trong kMapHashtags và có tọa độ hợp lệ
      final filtered = posts.where((p) {
        if (p.location == null) return false;
        final tags = p.hashtags?.map((t) => t.toLowerCase()).toList() ?? [];
        return tags.any((t) => kMapHashtags.contains(t));
      }).toList();

      // Kết hợp bài viết từ API và danh sách bài viết mẫu để luôn có dữ liệu kiểm tra
      final combined = [...filtered];
      for (final sample in _getSampleTaggedPosts()) {
        if (!combined.any((p) => p.id == sample.id)) {
          combined.add(sample);
        }
      }

      taggedPosts.value = combined;
      _buildPostMarkers();
    } catch (e) {
      debugPrint('MapController loadTaggedPosts error: $e');
      // Nếu API gặp sự cố hoặc offline, đảm bảo vẫn có bài viết mẫu hiển thị
      if (taggedPosts.isEmpty) {
        taggedPosts.value = _getSampleTaggedPosts();
        _buildPostMarkers();
      }
    }
  }

  void _buildPostMarkers() {
    // Xóa marker bài viết cũ, giữ search_result và sos nếu có
    markers.removeWhere(
      (m) =>
          m.key is ValueKey &&
          (m.key as ValueKey).value.toString().startsWith('post_'),
    );

    for (final post in taggedPosts) {
      final loc = post.location;
      if (loc == null) continue;

      // Màu marker theo hashtag đầu tiên khớp
      final matchingTags = (post.hashtags ?? [])
          .map((t) => t.toLowerCase())
          .where((t) => kMapHashtags.contains(t))
          .toList();
      final firstTag = matchingTags.isNotEmpty ? matchingTags.first : '';
      final displayTag = firstTag.isNotEmpty
          ? '#$firstTag'
          : ((post.hashtags?.isNotEmpty ?? false) ? post.hashtags!.first : '');
      final tagColor = _colorForTag(firstTag);

      markers.add(
        fm.Marker(
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
        ),
      );
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

    // Bỏ qua gọi API nếu là bài viết mẫu
    if (p.id!.startsWith('sample_')) return;

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

    // Bỏ qua gọi API nếu là bài viết mẫu
    if (p.id?.startsWith('sample_') ?? false) return;

    try {
      await _followRepository.followUser(userId);
    } catch (_) {
      postRx.value = p.copyWith(isFollowedByCurrentUser: wasFollowing);
      _syncToTaggedPosts(postRx.value);
    }
  }

  void _reportPost(TrafficPostModel post) {
    if (post.id == null) return;

    // Bỏ qua gọi API nếu là bài viết mẫu
    if (post.id!.startsWith('sample_')) {
      CustomAlert.showSuccess('Đã báo cáo bài viết');
      return;
    }

    _postRepository
        .reportPost(postId: post.id!, reason: 'Nội dung không phù hợp')
        .then((_) => CustomAlert.showSuccess('Đã báo cáo bài viết'))
        .catchError((e) => CustomAlert.showError(e.toString()));
  }

  /// Đồng bộ thay đổi bài viết vào danh sách taggedPosts
  void _syncToTaggedPosts(TrafficPostModel updated) {
    final idx = taggedPosts.indexWhere((p) => p.id == updated.id);
    if (idx != -1) taggedPosts[idx] = updated;
  }

  void _addDummyPolyline() {
    polylines.add(
      fm.Polyline(
        points: const [
          LatLng(21.028511, 105.804817),
          LatLng(21.029511, 105.805817),
          LatLng(21.030511, 105.806817),
          LatLng(21.031511, 105.807817),
        ],
        color: Colors.blue,
        strokeWidth: 5.0,
      ),
    );
  }

  void _buildSosMarkers() {
    // 1. Dọn dẹp các marker SOS cũ (giữ lại marker bài viết 'post_' và 'search_result')
    markers.removeWhere(
      (m) =>
          m.key is ValueKey &&
          (m.key as ValueKey).value.toString().startsWith('sos_'),
    );

    // 2. Lấy dữ liệu từ Service
    final sosList = SosStreamService.to.sosList;

    // 3. Vẽ lại toàn bộ Marker SOS
    for (final sos in sosList) {
      if (sos.latitude == null || sos.longitude == null) continue;

      markers.add(
        fm.Marker(
          key: ValueKey('sos_${sos.sosId}'),
          point: LatLng(sos.latitude!, sos.longitude!),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => SosBottomSheet.show(sos: sos),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.pinkAccent.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emergency,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }
  }
}
