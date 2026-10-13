import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:traffic_app/widgets/custom_alert.dart';
import 'package:traffic_app/widgets/custom_dialog.dart';

import '../../../config/demo_config.dart';
import '../../../data/models/traffic_post_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../data/repositories/traffic_post_repository.dart';
import '../../../services/storage_service.dart';
import '../widgets/report_bottom_sheet.dart';
import '../widgets/voice_search_bottom_sheet.dart';

class DashboardController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final TrafficPostRepository _postRepository = TrafficPostRepository();
  final FollowRepository _followRepository = FollowRepository();
  final StorageService _storageService = Get.find<StorageService>();

  /// ID của user hiện tại (dùng để ẩn nút follow trên bài viết của chính mình)
  int? get currentUserId => _storageService.getUserId();

  final refreshController = RefreshController(initialRefresh: false);
  final ScrollController scrollController = ScrollController();

  // State management
  final posts = <TrafficPostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = ''.obs;
  final recognizedText = ''.obs; 

  // Animation: id của bài viết mới nhất vừa được prepend
  final newPostId = RxnString();

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
  final int pageSize = 10;
  String currentLocation = '';

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
    _initializeLocation();
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
      message: (!kIsWeb && Platform.isIOS)
          ? 'dashboard_voice_permission_message_ios'.tr
          : 'dashboard_voice_permission_message'.tr,
      confirmText: 'dashboard_voice_open_settings'.tr,
      cancelText: 'chatbot_cancel'.tr,
      onConfirm: () {
        Get.back();
        openAppSettings();
      },
      type: DialogType.warning,
    );
  }

  /// Bắt đầu / dừng tìm kiếm bằng giọng nói
  Future<void> openVoiceSearch() async {
    if (kIsWeb || DemoConfig.isDemoMode) {
      searchController.text = 'Kẹt xe Cầu Giấy';
      CustomAlert.showSuccess('Mô phỏng giọng nói: "Kẹt xe Cầu Giấy"');
      return;
    }

    // Xin quyền và khởi tạo trước khi bật UI
    _speechToText = SpeechToText();
    _speechAvailable = await _speechToText.initialize(onError: _onSpeechError);

    if (!_speechAvailable) {
      _showVoicePermissionDialog();
      return;
    }

    // Mở Bottom Sheet
    Get.bottomSheet(
      const VoiceSearchBottomSheet(), 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      // Bắt sự kiện khi người dùng vuốt xuống để tắt Bottom Sheet
      if (isListening.value) {
        stopVoiceSearch();
      }
    });

    // Bắt đầu lắng nghe
    startListening();
  }

  /// 2. Bắt đầu thu âm
  Future<void> startListening() async {
    isListening.value = true;
    recognizedText.value = ''; // Reset lại chữ mỗi lần bật mic
    searchController.clear(); 

    await _speechToText.listen(
      onResult: (result) {
        // Cập nhật text realtime cho Bottom Sheet
        recognizedText.value = result.recognizedWords; 
        
        // Đổ text vào ô search luôn
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
        partialResults: true, // Bắt buộc true để hiện chữ ngay khi đang nói
        cancelOnError: true,
      ),
    );
  }

  /// 3. Dừng thu âm và đóng Bottom Sheet
  Future<void> stopVoiceSearch() async {
    isListening.value = false;
    await _speechToText.stop();
    
    // Đóng Bottom Sheet nếu nó đang mở
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

  /// Khởi tạo location từ storage và load posts
  void _initializeLocation() async {
    // Lấy province từ user profile hoặc default
    final prefs = _storageService;
    currentLocation = prefs.getString('userProvince') ?? 'Hà Nội';

    // Load posts lần đầu
    await loadPosts(refresh: true);
  }

  /// Load danh sách bài viết
  /// [refresh]: true nếu muốn load lại từ đầu (pull to refresh)
  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      currentPage = 0;
      hasMore.value = true;
      errorMessage.value = '';
    }

    if (!hasMore.value) return;

    // Set loading state
    if (refresh) {
      isLoading.value = true;
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
          posts.value = newPosts;
          refreshController.refreshCompleted();
        } else {
          posts.addAll(newPosts);
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
      // Save to storage
      _storageService.setString('userProvince', location);
      loadPosts(refresh: true);
    }
  }

  /// Thêm bài viết mới lên đầu danh sách (không rebuild toàn trang)
  void prependPost(TrafficPostModel post) {
    if (post.id != null) {
      likedState(post.id!).value = post.isLiked ?? false;
      likeCount(post.id!).value = post.likes ?? 0;
      if (post.userId != null) {
        followedState(post.userId!).value =
            post.isFollowedByCurrentUser ?? false;
      }
    }
    newPostId.value = post.id;
    posts.insert(0, post);
  }

  /// Xóa newPostId sau khi animation kết thúc
  void clearNewPostId() {
    newPostId.value = null;
  }

  /// Toggle like/unlike post với Optimistic Update
  /// - Cập nhật UI ngay lập tức (không chờ API)
  /// - Gọi API ở nền
  /// - Nếu API lỗi: rollback lại trạng thái cũ
  Future<void> toggleLike(TrafficPostModel post) async {
    if (post.id == null) return;

    final likedRx = likedState(post.id!);
    final countRx = likeCount(post.id!);
    final wasLiked = likedRx.value;
    final prevCount = countRx.value;

    // Optimistic update: chỉ rebuild phần like của bài đó
    likedRx.value = !wasLiked;
    countRx.value = wasLiked ? prevCount - 1 : prevCount + 1;

    try {
      await _postRepository.likePost(post.id!);
    } catch (_) {
      // Rollback nếu API thất bại
      likedRx.value = wasLiked;
      countRx.value = prevCount;
    }
  }

  /// Toggle follow/unfollow user với Optimistic Update
  Future<void> toggleFollow(TrafficPostModel post) async {
    if (post.userId == null) return;

    final userId = int.tryParse(post.userId!);
    if (userId == null) return;

    final followedRx = followedState(post.userId!);
    final wasFollowed = followedRx.value;

    // Optimistic update: tất cả bài của cùng userId đều cập nhật
    followedRx.value = !wasFollowed;

    try {
      await _followRepository.followUser(userId);
    } catch (_) {
      // Rollback nếu API thất bại
      followedRx.value = wasFollowed;
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
}
