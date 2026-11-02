import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:traffic_app/widgets/custom_alert.dart';
import 'package:traffic_app/widgets/custom_dialog.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../data/repositories/traffic_post_repository.dart';
import '../../../services/storage_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../profile/controllers/user_profile_controller.dart';
import '../widgets/dashboard_filter_bottom_sheet.dart';
import '../widgets/edit_post_bottom_sheet.dart';
import '../widgets/report_bottom_sheet.dart';
import '../widgets/voice_search_bottom_sheet.dart';

/// Các tùy chọn sắp xếp bài viết trên Trang chủ
enum PostSortOption { newest, nearest, mostLiked, reputation }

/// Các mốc lọc theo thời gian đăng bài
enum PostTimeFilter { all, last1Hour, last3Hours, today, last7Days }

class DashboardController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final TrafficPostRepository _postRepository = TrafficPostRepository();
  final FollowRepository _followRepository = FollowRepository();
  final StorageService _storageService = Get.find<StorageService>();

  /// ID của user hiện tại (dùng để ẩn nút follow trên bài viết của chính mình)
  int? get currentUserId => _storageService.getUserId();

  final refreshController = RefreshController(initialRefresh: false);
  final ScrollController scrollController = ScrollController();

  // Danh sách bài viết gốc đã tải từ server và danh sách sau khi áp dụng bộ lọc
  final List<TrafficPostModel> _allPosts = <TrafficPostModel>[];
  final posts = <TrafficPostModel>[].obs;

  // Bài viết mới nhận qua WebSocket đang chờ người dùng bấm xem
  final pendingRealtimePosts = <TrafficPostModel>[].obs;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = ''.obs;
  final recognizedText = ''.obs;

  // Animation: id của bài viết mới nhất vừa được prepend
  final newPostId = RxnString();

  // Tọa độ hiện tại của người dùng phục vụ tính khoảng cách & lọc "Gần tôi"
  final userLat = RxnDouble();
  final userLng = RxnDouble();
  final isFetchingLocation = false.obs;

  bool get hasUserLocation =>
      userLat.value != null &&
      userLng.value != null &&
      userLat.value != 0.0 &&
      userLng.value != 0.0;

  // Trạng thái Bộ lọc & Sắp xếp
  final isNearbyEnabled = false.obs;
  final nearbyRadiusKm = 5.0.obs;
  static const List<double> availableRadiiKm = [1.0, 3.0, 5.0, 10.0, 25.0];

  final selectedHashtag = RxnString();
  final onlyFollowing = false.obs;
  final selectedTimeFilter = PostTimeFilter.all.obs;
  final selectedSort = PostSortOption.newest.obs;

  /// Kiểm tra có bộ lọc nào đang kích hoạt không
  bool get hasActiveFilters =>
      isNearbyEnabled.value ||
      selectedHashtag.value != null ||
      onlyFollowing.value ||
      selectedTimeFilter.value != PostTimeFilter.all ||
      selectedSort.value != PostSortOption.newest;

  /// Đếm số lượng tiêu chí lọc đang bật để hiển thị badge trên nút Filter
  int get activeFilterCount {
    int count = 0;
    if (isNearbyEnabled.value) count++;
    if (selectedHashtag.value != null) count++;
    if (onlyFollowing.value) count++;
    if (selectedTimeFilter.value != PostTimeFilter.all) count++;
    if (selectedSort.value != PostSortOption.newest) count++;
    return count;
  }

  // Per-post reactive state (tránh rebuild toàn bộ list khi like/follow)
  final _likedStates = <String, RxBool>{};
  final _likeCounts = <String, RxInt>{};
  // Follow được key bởi userId để tất cả bài cùng người đồng bộ nhau
  final _followedStates = <String, RxBool>{};

  RxBool likedState(String postId) =>
      _likedStates.putIfAbsent(postId, () => false.obs);
  RxInt likeCount(String postId) =>
      _likeCounts.putIfAbsent(postId, () => 0.obs);
  RxBool followedState(String userId) =>
      _followedStates.putIfAbsent(userId, () => false.obs);

  void _syncPostStates(List<TrafficPostModel> newPosts) {
    for (final p in newPosts) {
      if (p.id == null) continue;
      likedState(p.id!).value = p.isLiked ?? false;
      likeCount(p.id!).value = p.likes ?? 0;
      if (p.userId != null) {
        followedState(p.userId!).value = p.isFollowedByCurrentUser ?? false;
      }
    }
  }

  /// Đồng bộ trạng thái Follow từ màn hình khác (Map, UserProfile)
  void syncFollowFromExternal(String userId, bool isFollowed) {
    followedState(userId).value = isFollowed;
    if (onlyFollowing.value) {
      _applyFiltersAndSort();
    }
  }

  // Search
  final isSearching = false.obs;
  final currentKeyword = ''.obs;
  Timer? _debounceTimer;

  // Voice search
  final isListening = false.obs;
  SpeechToText _speechToText = SpeechToText();
  bool _speechAvailable = false;

  // Pagination
  int currentPage = 0;
  final int pageSize = 20;
  String currentLocation = '';
  int _autoFetchAttempts = 0;

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    if (isListening.value) _speechToText.stop();
    scrollController.dispose();
    searchController.dispose();
    refreshController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    _initializeLocationAndPosts();
    _setupSearchDebounce();
  }

  /// Thiết lập debounce 300ms cho ô tìm kiếm
  void _setupSearchDebounce() {
    searchController.addListener(() {
      final keyword = searchController.text.trim();
      if (keyword == currentKeyword.value) return;

      _debounceTimer?.cancel();
      isSearching.value = keyword.isNotEmpty;

      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        currentKeyword.value = keyword;
        refreshController.resetNoData();
        loadPosts(refresh: true);
      });
    });
  }

  /// Xóa nội dung tìm kiếm và load lại tất cả bài viết
  void clearSearch() {
    searchController.clear();
  }

  void _showVoicePermissionDialog() {
    CustomDialog.showConfirm(
      context: Get.context!,
      title: 'dashboard_voice_permission_title'.tr,
      message: Platform.isIOS
          ? 'dashboard_voice_permission_message_ios'.tr
          : 'dashboard_voice_permission_message'.tr,
      confirmText: 'dashboard_voice_open_settings'.tr,
      cancelText: 'chatbot_cancel'.tr,
      onConfirm: () {
        openAppSettings();
      },
      type: DialogType.warning,
    );
  }

  /// Bắt đầu / dừng tìm kiếm bằng giọng nói
  Future<void> openVoiceSearch() async {
    _speechToText = SpeechToText();
    _speechAvailable = await _speechToText.initialize(onError: _onSpeechError);

    if (!_speechAvailable) {
      _showVoicePermissionDialog();
      return;
    }

    Get.bottomSheet(
      const VoiceSearchBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      if (isListening.value) {
        stopVoiceSearch();
      }
    });

    startListening();
  }

  /// Bắt đầu thu âm
  Future<void> startListening() async {
    isListening.value = true;
    recognizedText.value = '';
    searchController.clear();

    await _speechToText.listen(
      onResult: (result) {
        recognizedText.value = result.recognizedWords;
        searchController.text = result.recognizedWords;
        searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: searchController.text.length),
        );

        if (result.finalResult) {
          stopVoiceSearch();
        }
      },
      localeId: Get.locale?.toString().replaceAll('_', '-') ?? 'vi-VN',
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  /// Dừng thu âm và đóng Bottom Sheet
  Future<void> stopVoiceSearch() async {
    isListening.value = false;
    await _speechToText.stop();

    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    isListening.value = false;
    if (error.errorMsg != 'error_speech_timeout' &&
        error.errorMsg != 'error_no_match') {
      CustomAlert.show(
        message: 'dashboard_voice_error'.tr,
        type: AlertType.error,
      );
    }
  }

  /// Khởi tạo location từ storage, lấy tọa độ GPS nền và load posts
  Future<void> _initializeLocationAndPosts() async {
    final prefs = _storageService;
    currentLocation = prefs.getString('userProvince') ?? 'Hà Nội';

    // Chạy song song việc lấy tọa độ GPS và tải bài viết lần đầu
    unawaited(refreshUserLocation(requestPermissionIfDenied: false));
    await loadPosts(refresh: true);
  }

  /// Lấy tọa độ GPS hiện tại của người dùng để tính khoảng cách
  Future<bool> refreshUserLocation({
    bool requestPermissionIfDenied = false,
  }) async {
    try {
      isFetchingLocation.value = true;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (requestPermissionIfDenied && Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().requestLocationPermission();
        }
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (requestPermissionIfDenied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (requestPermissionIfDenied && Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().requestLocationPermission();
        }
        return false;
      }

      // 1. Lấy nhanh vị trí được cache gần nhất để hiển thị khoảng cách tức thì
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        userLat.value = lastKnown.latitude;
        userLng.value = lastKnown.longitude;
        _applyFiltersAndSort();
      }

      // 2. Lấy vị trí chính xác hiện tại
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      userLat.value = position.latitude;
      userLng.value = position.longitude;
      _applyFiltersAndSort();
      return true;
    } catch (e) {
      debugPrint('DashboardController refreshUserLocation error: $e');
      return hasUserLocation;
    } finally {
      isFetchingLocation.value = false;
    }
  }

  /// Tính khoảng cách (km) từ vị trí hiện tại của người dùng tới bài viết
  double? getDistanceKm(TrafficPostModel post) {
    if (!hasUserLocation) return null;
    final loc = post.location;
    if (loc == null || (loc.lat == 0.0 && loc.lng == 0.0)) return null;

    final meters = Geolocator.distanceBetween(
      userLat.value!,
      userLng.value!,
      loc.lat,
      loc.lng,
    );
    return meters / 1000.0;
  }

  /// Định dạng khoảng cách hiển thị thân thiện (vd: "450 m", "2.4 km")
  String? formatDistance(TrafficPostModel post) {
    final km = getDistanceKm(post);
    if (km == null) return null;
    if (km < 1.0) {
      final meters = (km * 1000).round().clamp(10, 999);
      return '$meters m';
    }
    if (km < 10.0) {
      return '${km.toStringAsFixed(1)} km';
    }
    return '${km.round()} km';
  }

  /// Áp dụng toàn bộ Bộ lọc & Sắp xếp lên `_allPosts` để cập nhật `posts`
  void _applyFiltersAndSort() {
    // 0. Luôn chỉ hiển thị bài có status hợp lệ (NORMAL) và loại bỏ bài DELETED
    Iterable<TrafficPostModel> result = _allPosts.where((p) => p.isVisible);

    // 1. Lọc theo từ khóa tìm kiếm (nếu có)
    final kw = currentKeyword.value.trim().toLowerCase();
    if (kw.isNotEmpty) {
      result = result.where((p) {
        final contentMatch = (p.content ?? '').toLowerCase().contains(kw);
        final addressMatch = (p.location?.address ?? '').toLowerCase().contains(
          kw,
        );
        final userMatch = (p.userName ?? '').toLowerCase().contains(kw);
        final tagMatch = (p.hashtags ?? []).any(
          (t) => t.toLowerCase().contains(kw),
        );
        return contentMatch || addressMatch || userMatch || tagMatch;
      });
    }

    // 2. Lọc theo Hashtag / Loại sự cố
    final activeTag = selectedHashtag.value?.toLowerCase();
    if (activeTag != null && activeTag.isNotEmpty) {
      result = result.where((p) {
        final tags = (p.hashtags ?? []).map(
          (t) => t.toLowerCase().replaceAll('#', ''),
        );
        return tags.contains(activeTag);
      });
    }

    // 3. Lọc theo "Đang theo dõi"
    if (onlyFollowing.value) {
      result = result.where((p) {
        if (p.userId == null) return false;
        return followedState(p.userId!).value;
      });
    }

    // 4. Lọc theo Khoảng thời gian
    final timeFilter = selectedTimeFilter.value;
    if (timeFilter != PostTimeFilter.all) {
      final now = DateTime.now();
      result = result.where((p) {
        final ts = p.timestamp;
        if (ts == null) return false;
        final diff = now.difference(ts);
        switch (timeFilter) {
          case PostTimeFilter.last1Hour:
            return diff.inMinutes <= 60;
          case PostTimeFilter.last3Hours:
            return diff.inHours <= 3;
          case PostTimeFilter.today:
            return ts.year == now.year &&
                ts.month == now.month &&
                ts.day == now.day;
          case PostTimeFilter.last7Days:
            return diff.inDays <= 7;
          case PostTimeFilter.all:
            return true;
        }
      });
    }

    // 5. Lọc theo Bán kính xung quanh vị trí hiện tại ("Gần tôi")
    if (isNearbyEnabled.value && hasUserLocation) {
      final maxKm = nearbyRadiusKm.value;
      result = result.where((p) {
        final km = getDistanceKm(p);
        return km != null && km <= maxKm;
      });
    }

    final filteredList = result.toList();

    // 6. Sắp xếp danh sách
    final sortOption = selectedSort.value;
    switch (sortOption) {
      case PostSortOption.nearest:
        if (hasUserLocation) {
          filteredList.sort((a, b) {
            final distA = getDistanceKm(a) ?? double.infinity;
            final distB = getDistanceKm(b) ?? double.infinity;
            return distA.compareTo(distB);
          });
        }
        break;
      case PostSortOption.mostLiked:
        filteredList.sort((a, b) {
          final likesA = a.id != null ? likeCount(a.id!).value : (a.likes ?? 0);
          final likesB = b.id != null ? likeCount(b.id!).value : (b.likes ?? 0);
          return likesB.compareTo(likesA);
        });
        break;
      case PostSortOption.reputation:
        filteredList.sort((a, b) {
          final repA = a.userReputationScore ?? 0;
          final repB = b.userReputationScore ?? 0;
          return repB.compareTo(repA);
        });
        break;
      case PostSortOption.newest:
        filteredList.sort((a, b) {
          final timeA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });
        break;
    }

    posts.assignAll(filteredList);
  }

  /// Tự động tải thêm trang tiếp theo nếu bật bộ lọc mà số kết quả khớp quá ít (< 4 bài)
  Future<void> _ensureEnoughFilteredPosts() async {
    if (!hasActiveFilters) return;
    while (posts.length < 4 &&
        hasMore.value &&
        !isLoading.value &&
        !isLoadingMore.value &&
        _autoFetchAttempts < 2) {
      _autoFetchAttempts++;
      await loadPosts(refresh: false);
    }
    _autoFetchAttempts = 0;
  }

  /// Bật / tắt bộ lọc "Gần tôi"
  Future<void> toggleNearbyFilter({double? radiusKm}) async {
    if (isNearbyEnabled.value && radiusKm == null) {
      isNearbyEnabled.value = false;
      if (selectedSort.value == PostSortOption.nearest) {
        selectedSort.value = PostSortOption.newest;
      }
      _applyFiltersAndSort();
      return;
    }

    if (!hasUserLocation) {
      final ok = await refreshUserLocation(requestPermissionIfDenied: true);
      if (!ok) {
        CustomAlert.showWarning('dashboard_need_location_for_nearby'.tr);
        return;
      }
    }

    if (radiusKm != null) {
      nearbyRadiusKm.value = radiusKm;
    }
    isNearbyEnabled.value = true;
    selectedSort.value = PostSortOption.nearest;
    _applyFiltersAndSort();
    await _ensureEnoughFilteredPosts();
  }

  /// Thay đổi bán kính lọc "Gần tôi"
  Future<void> setNearbyRadius(double radiusKm) async {
    await toggleNearbyFilter(radiusKm: radiusKm);
  }

  /// Bật / tắt lọc nhanh theo Hashtag
  Future<void> toggleHashtagFilter(String rawTag) async {
    final cleanTag = rawTag.replaceAll('#', '').trim().toLowerCase();
    if (cleanTag.isEmpty) return;

    if (selectedHashtag.value == cleanTag) {
      selectedHashtag.value = null;
    } else {
      selectedHashtag.value = cleanTag;
    }
    _applyFiltersAndSort();
    await _ensureEnoughFilteredPosts();
  }

  /// Bật / tắt lọc bài viết từ người đang theo dõi
  Future<void> toggleFollowingFilter() async {
    onlyFollowing.value = !onlyFollowing.value;
    _applyFiltersAndSort();
    await _ensureEnoughFilteredPosts();
  }

  /// Mở Bottom Sheet Bộ lọc & Sắp xếp nâng cao
  void openFilterBottomSheet() {
    Get.bottomSheet(
      const DashboardFilterBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Áp dụng đồng thời các tùy chọn từ Bottom Sheet Bộ lọc
  Future<void> applyAdvancedFilters({
    required PostSortOption sort,
    required bool nearbyEnabled,
    required double radiusKm,
    required PostTimeFilter timeFilter,
    required String? hashtag,
    required bool followingOnly,
  }) async {
    if ((nearbyEnabled || sort == PostSortOption.nearest) && !hasUserLocation) {
      final ok = await refreshUserLocation(requestPermissionIfDenied: true);
      if (!ok) {
        CustomAlert.showWarning('dashboard_need_location_for_nearby'.tr);
      }
    }

    selectedSort.value = (sort == PostSortOption.nearest && !hasUserLocation)
        ? PostSortOption.newest
        : sort;
    isNearbyEnabled.value = nearbyEnabled && hasUserLocation;
    nearbyRadiusKm.value = radiusKm;
    selectedTimeFilter.value = timeFilter;
    selectedHashtag.value = hashtag;
    onlyFollowing.value = followingOnly;

    _applyFiltersAndSort();
    await _ensureEnoughFilteredPosts();
  }

  /// Đặt lại tất cả bộ lọc về mặc định
  void resetAllFilters() {
    isNearbyEnabled.value = false;
    nearbyRadiusKm.value = 5.0;
    selectedHashtag.value = null;
    onlyFollowing.value = false;
    selectedTimeFilter.value = PostTimeFilter.all;
    selectedSort.value = PostSortOption.newest;
    _applyFiltersAndSort();
  }

  /// Chuyển sang tab Bản đồ và di chuyển tới vị trí của bài viết
  void openPostOnMap(TrafficPostModel post) {
    if (post.location == null) return;
    if (Get.isRegistered<MapController>()) {
      Get.find<MapController>().focusOnPost(post);
    }
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(1);
    }
  }

  /// Nhận bài viết mới realtime từ STOMP WebSocket (do MapController chuyển tiếp)
  void onRealtimePostReceived(TrafficPostModel post) {
    if (post.id == null) return;
    // Nếu bài viết bị ẩn/xóa (DELETED), loại bỏ khỏi danh sách hiện tại
    if (!post.isVisible) {
      syncPostDeleted(post.id!);
      return;
    }
    // Bỏ qua nếu là bài viết của chính mình (vì CameraController đã prepend trực tiếp)
    if (currentUserId != null && post.userId == currentUserId.toString()) {
      return;
    }
    // Bỏ qua nếu bài viết đã tồn tại
    if (_allPosts.any((p) => p.id == post.id) ||
        pendingRealtimePosts.any((p) => p.id == post.id)) {
      return;
    }
    pendingRealtimePosts.insert(0, post);
  }

  /// Hiển thị các bài viết mới nhận qua WebSocket lên đầu danh sách khi người dùng bấm vào banner
  void applyPendingRealtimePosts() {
    if (pendingRealtimePosts.isEmpty) return;
    _syncPostStates(pendingRealtimePosts);
    final newestId = pendingRealtimePosts.first.id;
    for (final p in pendingRealtimePosts.reversed) {
      if (!_allPosts.any((existing) => existing.id == p.id)) {
        _allPosts.insert(0, p);
      }
    }
    pendingRealtimePosts.clear();
    newPostId.value = newestId;
    _applyFiltersAndSort();
    scrollToTop();
  }

  /// Load danh sách bài viết
  /// [refresh]: true nếu muốn load lại từ đầu (pull to refresh)
  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      currentPage = 0;
      hasMore.value = true;
      errorMessage.value = '';
      pendingRealtimePosts.clear();
      unawaited(refreshUserLocation(requestPermissionIfDenied: false));
    }

    if (!hasMore.value) return;

    if (refresh) {
      isLoading.value = true;
      _allPosts.clear();
      posts.clear();
    } else {
      isLoadingMore.value = true;
    }

    try {
      final newPosts = await _postRepository.getPosts(
        location: currentLocation,
        page: currentPage,
        size: pageSize,
        keyword: currentKeyword.value.isNotEmpty ? currentKeyword.value : null,
      );

      if (newPosts.isEmpty) {
        hasMore.value = false;
        if (refresh) {
          refreshController.refreshCompleted();
        } else {
          refreshController.loadNoData();
        }
      } else {
        _syncPostStates(newPosts);
        if (refresh) {
          _allPosts
            ..clear()
            ..addAll(newPosts);
          _applyFiltersAndSort();
          refreshController.refreshCompleted();
        } else {
          for (final p in newPosts) {
            if (p.id == null || !_allPosts.any((e) => e.id == p.id)) {
              _allPosts.add(p);
            }
          }
          _applyFiltersAndSort();
          refreshController.loadComplete();
        }
        currentPage++;
      }

      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = e.toString();
      if (refresh) {
        refreshController.refreshFailed();
        CustomAlert.showError(e.toString());
      } else {
        refreshController.loadFailed();
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Load more khi scroll đến cuối danh sách
  Future<void> loadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await loadPosts(refresh: false);
    } else if (!hasMore.value) {
      refreshController.loadNoData();
    }
  }

  /// Refresh toàn bộ danh sách
  @override
  Future<void> refresh() async {
    refreshController.resetNoData();
    await loadPosts(refresh: true);
  }

  /// Thay đổi location và load lại posts
  void changeLocation(String location) {
    if (location != currentLocation) {
      currentLocation = location;
      _storageService.setString('userProvince', location);
      loadPosts(refresh: true);
    }
  }

  /// Thêm bài viết mới lên đầu danh sách (không rebuild toàn trang)
  void prependPost(TrafficPostModel post) {
    if (!post.isVisible) return;
    if (post.id != null) {
      likedState(post.id!).value = post.isLiked ?? false;
      likeCount(post.id!).value = post.likes ?? 0;
      if (post.userId != null) {
        followedState(post.userId!).value =
            post.isFollowedByCurrentUser ?? false;
      }
    }
    newPostId.value = post.id;
    _allPosts.removeWhere((p) => p.id != null && p.id == post.id);
    _allPosts.insert(0, post);
    _applyFiltersAndSort();
  }

  /// Xóa newPostId sau khi animation kết thúc
  void clearNewPostId() {
    newPostId.value = null;
  }

  /// Toggle like/unlike post với Optimistic Update
  Future<void> toggleLike(TrafficPostModel post) async {
    if (post.id == null) return;

    final likedRx = likedState(post.id!);
    final countRx = likeCount(post.id!);
    final wasLiked = likedRx.value;
    final prevCount = countRx.value;

    likedRx.value = !wasLiked;
    countRx.value = wasLiked ? prevCount - 1 : prevCount + 1;
    if (Get.isRegistered<MapController>()) {
      Get.find<MapController>().syncPostLikeState(
        post.id!,
        likedRx.value,
        countRx.value,
      );
    }

    try {
      await _postRepository.likePost(post.id!);
    } catch (_) {
      likedRx.value = wasLiked;
      countRx.value = prevCount;
      if (Get.isRegistered<MapController>()) {
        Get.find<MapController>().syncPostLikeState(
          post.id!,
          wasLiked,
          prevCount,
        );
      }
    }
  }

  /// Toggle follow/unfollow user với Optimistic Update
  Future<void> toggleFollow(TrafficPostModel post) async {
    if (post.userId == null) return;

    final userId = int.tryParse(post.userId!);
    if (userId == null) return;

    final followedRx = followedState(post.userId!);
    final wasFollowed = followedRx.value;

    followedRx.value = !wasFollowed;
    if (onlyFollowing.value) {
      _applyFiltersAndSort();
    }
    if (Get.isRegistered<MapController>()) {
      Get.find<MapController>().syncUserFollowState(
        post.userId!,
        followedRx.value,
      );
    }

    try {
      await _followRepository.followUser(userId);
    } catch (_) {
      followedRx.value = wasFollowed;
      if (onlyFollowing.value) {
        _applyFiltersAndSort();
      }
      if (Get.isRegistered<MapController>()) {
        Get.find<MapController>().syncUserFollowState(
          post.userId!,
          wasFollowed,
        );
      }
    }
  }

  /// Report post
  void reportPost(TrafficPostModel post) {
    if (post.id == null) return;

    Get.bottomSheet(
      ReportBottomSheet(
        onReport: (reason) async {
          try {
            await _postRepository.reportPost(postId: post.id!, reason: reason);

            Get.back();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              CustomAlert.showSuccess('dashboard_report_success'.tr);
            });
          } catch (e) {
            Get.back();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              CustomAlert.showError(e.toString());
            });
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Đồng bộ nội dung bài viết khi được chỉnh sửa
  void syncPostContentUpdated(String postId, String newContent) {
    bool changed = false;
    for (int i = 0; i < _allPosts.length; i++) {
      if (_allPosts[i].id == postId) {
        _allPosts[i] = _allPosts[i].copyWith(content: newContent);
        changed = true;
      }
    }
    for (int i = 0; i < pendingRealtimePosts.length; i++) {
      if (pendingRealtimePosts[i].id == postId) {
        pendingRealtimePosts[i] = pendingRealtimePosts[i].copyWith(
          content: newContent,
        );
      }
    }
    if (changed) {
      _applyFiltersAndSort();
    }
  }

  /// Đồng bộ khi bài viết bị xóa
  void syncPostDeleted(String postId) {
    final beforeLen = _allPosts.length;
    _allPosts.removeWhere((p) => p.id == postId);
    pendingRealtimePosts.removeWhere((p) => p.id == postId);
    _likedStates.remove(postId);
    _likeCounts.remove(postId);
    if (_allPosts.length != beforeLen) {
      _applyFiltersAndSort();
    }
  }

  /// Mở Bottom Sheet chỉnh sửa nội dung bài viết của chính mình
  void openEditPostSheet(TrafficPostModel post) {
    final postId = post.id;
    if (postId == null || postId.isEmpty) return;

    EditPostBottomSheet.show(
      post: post,
      onSave: (newContent) async {
        try {
          await _postRepository.updatePost(
            postId: postId,
            type: (post.type != null && post.type!.isNotEmpty)
                ? post.type!
                : 'TRAFFIC_JAM',
            content: newContent,
            lat: post.location?.lat ?? 0.0,
            lng: post.location?.lng ?? 0.0,
            address: post.location?.address ?? '',
            hashtags: post.hashtags ?? const <String>[],
            status: (post.status != null && post.status!.isNotEmpty)
                ? post.status!
                : 'NORMAL',
            timestamp: post.timestamp ?? DateTime.now().toUtc(),
          );

          syncPostContentUpdated(postId, newContent);
          final ownerId = post.userId ?? (currentUserId?.toString() ?? '');
          UserProfileController.syncExternalPostUpdated(
            ownerId,
            postId,
            newContent,
          );
          if (Get.isRegistered<MapController>()) {
            Get.find<MapController>().syncPostContentUpdated(
              postId,
              newContent,
            );
          }

          if (Get.isBottomSheetOpen ?? false) {
            Get.back();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            CustomAlert.showSuccess('post_update_success'.tr);
          });
        } catch (e) {
          CustomAlert.showError(e.toString());
        }
      },
    );
  }

  /// Hiển thị hộp thoại xác nhận trước khi xóa bài viết của chính mình
  void confirmDeletePost(BuildContext context, TrafficPostModel post) {
    final postId = post.id;
    if (postId == null || postId.isEmpty) return;

    CustomDialog.showConfirm(
      context: context,
      title: 'post_delete_confirm_title'.tr,
      message: 'post_delete_confirm_message'.tr,
      confirmText: 'post_delete_confirm_btn'.tr,
      cancelText: 'profile_cancel'.tr,
      type: DialogType.error,
      onConfirm: () => deletePost(post),
    );
  }

  /// Xóa bài viết và đồng bộ sang các màn hình
  Future<void> deletePost(TrafficPostModel post) async {
    final postId = post.id;
    if (postId == null || postId.isEmpty) return;

    try {
      await _postRepository.deletePost(postId);

      syncPostDeleted(postId);
      final ownerId = post.userId ?? (currentUserId?.toString() ?? '');
      UserProfileController.syncExternalPostDeleted(ownerId, postId);
      if (Get.isRegistered<MapController>()) {
        Get.find<MapController>().syncPostDeleted(postId);
      }

      CustomAlert.showSuccess('post_delete_success'.tr);
    } catch (e) {
      CustomAlert.showError(e.toString());
    }
  }
}
