import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:traffic_app/widgets/custom_alert.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../data/models/user_info_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../data/repositories/traffic_post_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../services/storage_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/widgets/report_bottom_sheet.dart';
import '../../../routes/app_pages.dart';
import 'profile_controller.dart';

class UserProfileController extends GetxController {
  // profile cache
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  final _likedStates = <String, RxBool>{};
  final _likeCounts = <String, RxInt>{};
  // Follow được key bởi userId để tất cả bài cùng người đồng bộ nhau
  final _followedStates = <String, RxBool>{};

  // Các hàm xuất state ra UI (Rx) — dùng putIfAbsent để đảm bảo luôn trả về cùng 1 instance
  RxBool likedState(String postId) =>
      _likedStates.putIfAbsent(postId, () => false.obs);
  RxInt likeCount(String postId) =>
      _likeCounts.putIfAbsent(postId, () => 0.obs);
  RxBool followedState(String userId) =>
      _followedStates.putIfAbsent(userId, () => false.obs);

  final UserRepository _userRepo = UserRepository();
  final TrafficPostRepository _postRepository = TrafficPostRepository();
  final FollowRepository _followRepository = FollowRepository();
  final StorageService _storageService = Get.find<StorageService>();

  final refreshController = RefreshController(initialRefresh: false);
  final ScrollController scrollController = ScrollController();

  final userInfo = Rxn<UserInfoModel>();
  final posts = <TrafficPostModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = ''.obs;

  final isFollowing = false.obs;
  final totalLikes = 0.obs;

  int currentPage = 0;
  final int pageSize = 10;

  late final String targetUserId;
  late final bool isMyProfile;

  int? get currentUserId => _storageService.getUserId();

  @override
  void onInit() {
    super.onInit();
    final myId = currentUserId?.toString() ?? '';
    targetUserId = Get.arguments?['userId']?.toString() ?? myId;
    isMyProfile = (targetUserId == myId);

    _checkCacheAndLoad();
  }

  @override
  void onClose() {
    scrollController.dispose();
    refreshController.dispose();
    super.onClose();
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _checkCacheAndLoad() {
    if (_profileCache.containsKey(targetUserId)) {
      final cachedData = _profileCache[targetUserId]!;
      userInfo.value = cachedData['userInfo'];
      posts.assignAll(cachedData['posts']);

      initPostStates(cachedData['posts']);

      isFollowing.value = userInfo.value?.follow ?? false;
      _calculateTotalLikes();

      isLoading.value = false;

      loadProfileData(refresh: true, showLoading: false);
    } else {
      loadProfileData(refresh: true, showLoading: true);
    }
  }

  /// Hàm này dùng để khởi tạo trạng thái khi vừa tải danh sách bài viết về
  void initPostStates(List<TrafficPostModel> fetchedPosts) {
    final dashCtrl = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : null;

    for (var post in fetchedPosts) {
      final postId = post.id ?? '';
      if (postId.isEmpty) continue;

      // Ưu tiên state từ DashboardController nếu bài đó đã được like ở đó
      if (!_likedStates.containsKey(postId)) {
        final dashLiked = dashCtrl?.likedState(postId).value;
        _likedStates[postId] = (dashLiked ?? post.isLiked ?? false).obs;
      }
      if (!_likeCounts.containsKey(postId)) {
        final dashCount = dashCtrl?.likeCount(postId).value;
        _likeCounts[postId] = (dashCount ?? post.likes ?? 0).obs;
      }
      // Key bởi userId để đồng bộ tất cả bài của cùng 1 người
      final userId = post.userId ?? '';
      if (userId.isNotEmpty && !_followedStates.containsKey(userId)) {
        final dashFollowed = dashCtrl?.followedState(userId).value;
        _followedStates[userId] =
            (dashFollowed ?? post.isFollowedByCurrentUser ?? false).obs;
      }
    }
  }

  Future<void> loadProfileData({
    bool refresh = false,
    bool showLoading = true,
  }) async {
    if (refresh) {
      currentPage = 0;
      hasMore.value = true;
      errorMessage.value = '';
    }

    if (!hasMore.value) return;

    // Set loading state
    if (refresh) {
      if (showLoading) {
        isLoading.value = true;
        posts.clear(); // Xóa list cũ đi để hiện xương Shimmer
      }
    } else {
      isLoadingMore.value = true;
    }

    try {
      // Gọi API lấy UserInfo & Posts (có phân trang)
      final result = await _userRepo.getUserProfile(
        targetUserId,
        page: currentPage,
        size: pageSize,
      );

      final newUserInfo = result['userInfo'] as UserInfoModel;
      final newPosts = result['posts'] as List<TrafficPostModel>;

      initPostStates(newPosts);

      userInfo.value = newUserInfo;
      isFollowing.value = newUserInfo.follow ?? false;

      // Đồng bộ điểm uy tín và huy hiệu vào ProfileController và StorageService nếu là profile của chính mình
      if (isMyProfile) {
        StorageService.to.saveUserReputation(
          score: newUserInfo.reputationScore,
          badge: newUserInfo.badge,
          canCreatePost: newUserInfo.canCreatePost,
        );
        if (Get.isRegistered<ProfileController>()) {
          final pc = Get.find<ProfileController>();
          if (newUserInfo.reputationScore != null) {
            pc.reputationScore.value = newUserInfo.reputationScore!;
          }
          if (newUserInfo.badge != null) {
            pc.badge.value = newUserInfo.badge!;
          }
          if (newUserInfo.canCreatePost != null) {
            pc.canCreatePost.value = newUserInfo.canCreatePost!;
          }
        }
      }

      if (newPosts.isEmpty) {
        hasMore.value = false;
        if (refresh) {
          refreshController.refreshCompleted();
        } else {
          refreshController.loadNoData();
        }
      } else {
        if (refresh) {
          posts.value = newPosts;
          refreshController.refreshCompleted();

          // LƯU KẾT QUẢ MỚI VÀO BỘ NHỚ ĐỆM TĨNH ĐỂ LẦN SAU DÙNG
          _profileCache[targetUserId] = {
            'userInfo': newUserInfo,
            'posts': List<TrafficPostModel>.from(
              newPosts,
            ), // Tạo bản sao danh sách
          };
        } else {
          posts.addAll(newPosts);
          refreshController.loadComplete();
        }
        currentPage++;
      }

      errorMessage.value = '';
      _calculateTotalLikes();
    } catch (e) {
      errorMessage.value = e.toString();
      if (refresh) {
        refreshController.refreshFailed();
        // Chỉ văng lỗi bự lên màn hình nếu là lần đầu load và không có cache
        if (posts.isEmpty) CustomAlert.showError(e.toString());
      } else {
        refreshController.loadFailed();
      }
    } finally {
      if (showLoading) isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Load more khi scroll đến cuối danh sách (Gọi bởi SmartRefresher)
  Future<void> loadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await loadProfileData(refresh: false, showLoading: false);
    } else if (!hasMore.value) {
      refreshController.loadNoData();
    }
  }

  /// Refresh toàn bộ danh sách
  @override
  Future<void> refresh() async {
    refreshController.resetNoData();
    await loadProfileData(refresh: true, showLoading: true);
  }

  void _calculateTotalLikes() {
    totalLikes.value = _likeCounts.values.fold(0, (sum, rx) => sum + rx.value);
  }

  Future<void> toggleUserFollow() async {
    if (isMyProfile) return;

    // Optimistic Update cho Header
    isFollowing.value = !isFollowing.value;

    // Đồng bộ ngay sang DashboardController nếu đang tồn tại
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().followedState(targetUserId).value =
          isFollowing.value;
    }

    if (userInfo.value != null) {
      int currentFollowers = userInfo.value!.followersCount ?? 0;
      int newFollowers = isFollowing.value
          ? currentFollowers + 1
          : currentFollowers - 1;

      userInfo.value = userInfo.value!.copyWith(
        followersCount: newFollowers > 0 ? newFollowers : 0,
        follow: isFollowing.value,
      );
    }

    try {
      final userIdInt = int.tryParse(targetUserId);
      if (userIdInt != null) {
        await _followRepository.followUser(userIdInt);
      }
    } catch (_) {
      // Rollback cả 2 nơi
      isFollowing.value = !isFollowing.value;
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().followedState(targetUserId).value =
            isFollowing.value;
      }
      CustomAlert.showError('Không thể thực hiện. Vui lòng thử lại!');
    }
  }

  /// Mở màn hình quản lý theo dõi (Người theo dõi / Đang theo dõi)
  void openFollowManagement({int initialIndex = 0}) {
    if (!isMyProfile) return;
    Get.toNamed(
      Routes.FOLLOW_MANAGEMENT,
      arguments: {'initialIndex': initialIndex},
    )?.then((_) {
      // Làm mới lại số lượng người theo dõi và đang theo dõi sau khi trở về
      loadProfileData(refresh: true, showLoading: false);
    });
  }

  /// Toggle like/unlike post
  Future<void> toggleLike(TrafficPostModel post) async {
    final postId = post.id ?? '';
    if (postId.isEmpty) return;

    // 1. Lấy trạng thái hiện tại từ bộ Rx
    final isLiked = _likedStates[postId]?.value ?? false;
    final currentCount = _likeCounts[postId]?.value ?? 0;

    // 2. Optimistic update: chỉ cập nhật Rx của bài đó, không đụng đến RxList
    likedState(postId).value = !isLiked;
    likeCount(postId).value = isLiked ? currentCount - 1 : currentCount + 1;
    _calculateTotalLikes();
    // Sync về DashboardController để khi quay lại dashboard state nhất quán
    _syncLikeToDashboard(
      postId,
      !isLiked,
      isLiked ? currentCount - 1 : currentCount + 1,
    );

    try {
      // 3. Bắn API
      await _postRepository.likePost(postId);
    } catch (_) {
      // 4. Rollback nếu mạng lỗi
      likedState(postId).value = isLiked;
      likeCount(postId).value = currentCount;
      _calculateTotalLikes();
      _syncLikeToDashboard(postId, isLiked, currentCount);
    }
  }

  void _syncLikeToDashboard(String postId, bool isLiked, int count) {
    if (!Get.isRegistered<DashboardController>()) return;
    final dash = Get.find<DashboardController>();
    dash.likedState(postId).value = isLiked;
    dash.likeCount(postId).value = count;
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
              CustomAlert.showSuccess('Báo cáo bài viết thành công');
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
