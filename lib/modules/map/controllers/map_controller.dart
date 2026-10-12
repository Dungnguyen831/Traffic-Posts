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
  String get currentTileUrl {
    switch (currentMapType.value) {
      case AppMapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case AppMapType.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case AppMapType.normal:
      default:
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

    loadTaggedPosts();
    _markerRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadTaggedPosts(),
    );
    _addDummyPolyline();
    _checkLocationPermission();

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
  }

  /// Danh sách bài viết mẫu đa dạng hashtag để kiểm tra hiển thị Marker trên bản đồ
  List<TrafficPostModel> _getSampleTaggedPosts() {
    return [
      TrafficPostModel(
        id: 'sample_ketxe',
        userId: '101',
        userName: 'Nguyễn Văn Nam',
        content: 'Kẹt xe nghiêm trọng tại Ngã tư Cầu Giấy hướng về Kim Mã, các phương tiện di chuyển rất chậm.',
        hashtags: ['ketxe'],
        location: LocationModel(
          lat: 21.033500,
          lng: 105.800500,
          address: 'Ngã tư Cầu Giấy, Hà Nội',
        ),
        likes: 15,
        isLiked: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      TrafficPostModel(
        id: 'sample_tainan',
        userId: '102',
        userName: 'Trần Thị Mai',
        content: 'Va chạm giao thông nhẹ tại nút giao Kim Mã - Liễu Giai, đường hơi ùn ứ một làn xe.',
        hashtags: ['tainan'],
        location: LocationModel(
          lat: 21.031500,
          lng: 105.813000,
          address: 'Kim Mã - Liễu Giai, Ba Đình, Hà Nội',
        ),
        likes: 6,
        isLiked: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      TrafficPostModel(
        id: 'sample_ngaplutnuoc',
        userId: '103',
        userName: 'Lê Hoàng Anh',
        content: 'Đoạn đường ven sông Tô Lịch đang ngập nước khoảng 20-30cm sau mưa, các xe chú ý giảm tốc độ.',
        hashtags: ['ngaplutnuoc'],
        location: LocationModel(
          lat: 21.025000,
          lng: 105.802000,
          address: 'Đường Láng, Cầu Giấy, Hà Nội',
        ),
        likes: 24,
        isLiked: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      ),
      TrafficPostModel(
        id: 'sample_giaothong',
        userId: '104',
        userName: 'Đội CSGT Số 2',
        content: 'Đang có lực lượng CSGT điều tiết phân luồng giờ cao điểm, các phương tiện đi lại ổn định.',
        hashtags: ['giaothong'],
        location: LocationModel(
          lat: 21.029500,
          lng: 105.810000,
          address: 'Đường Kim Mã, Ba Đình, Hà Nội',
        ),
        likes: 42,
        isLiked: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
      ),
      TrafficPostModel(
        id: 'sample_sos',
        userId: '105',
        userName: 'Phạm Quốc Huy',
        content: 'Xe máy bị thủng lốp cần hỗ trợ vá săm lưu động gần cây xăng Giảng Võ.',
        hashtags: ['sos'],
        location: LocationModel(
          lat: 21.027000,
          lng: 105.818000,
          address: 'Giảng Võ, Đống Đa, Hà Nội',
        ),
        likes: 8,
        isLiked: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
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
