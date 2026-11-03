import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:traffic_app/widgets/custom_alert.dart';
import 'package:traffic_app/widgets/custom_dialog.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../data/models/user_info_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../data/repositories/traffic_post_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../services/storage_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../dashboard/widgets/edit_post_bottom_sheet.dart';
import '../../dashboard/widgets/report_bottom_sheet.dart';
import '../../map/controllers/map_controller.dart';
import '../../../routes/app_pages.dart';
import 'profile_controller.dart';

class UserProfileController extends GetxController {
  // profile cache
  static final Map<String, Map<String, dynamic>> _profileCache = {};

  static void clearCache() => _profileCache.clear();

  /// Đồng bộ nội dung bài viết được chỉnh sửa vào bộ nhớ đệm và các instance đang mở
  static void syncExternalPostUpdated(
    String userId,
    String postId,
    String newContent,
  ) {
    for (final entry in _profileCache.entries) {
      final cachedPosts = entry.value['posts'];
      if (cachedPosts is List<TrafficPostModel>) {
        final idx = cachedPosts.indexWhere((p) => p.id == postId);
        if (idx != -1) {
          cachedPosts[idx] = cachedPosts[idx].copyWith(content: newContent);
        }
      }
    }
    for (final tag in <String>['my_profile', userId]) {
      if (tag.isNotEmpty && Get.isRegistered<UserProfileController>(tag: tag)) {
        Get.find<UserProfileController>(
          tag: tag,
        )._applyLocalPostContentUpdate(postId, newContent);
      }
    }
  }

  /// Đồng bộ xóa bài viết khỏi bộ nhớ đệm và các instance đang mở
  static void syncExternalPostDeleted(String userId, String postId) {
    for (final entry in _profileCache.entries) {
      final cachedPosts = entry.value['posts'];
      if (cachedPosts is List<TrafficPostModel>) {
        cachedPosts.removeWhere((p) => p.id == postId);
      }
    }
    for (final tag in <String>['my_profile', userId]) {
      if (tag.isNotEmpty && Get.isRegistered<UserProfileController>(tag: tag)) {
        Get.find<UserProfileController>(tag: tag)._applyLocalPostDelete(postId);
      }
    }
  }

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
      final cachedPosts = (cachedData['posts'] as List<TrafficPostModel>)
          .where((p) => p.isVisible)
          .toList();
      posts.assignAll(cachedPosts);

      initPostStates(cachedPosts);

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
      final newPosts = (result['posts'] as List<TrafficPostModel>)
          .where((p) => p.isVisible)
          .toList();
      final rawPostCount = (result['rawPostCount'] as int?) ?? newPosts.length;

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

      if (rawPostCount == 0) {
        hasMore.value = false;
        if (refresh) {
          posts.clear();
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

    // Đồng bộ ngay sang DashboardController & MapController nếu đang tồn tại
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().syncFollowFromExternal(
        targetUserId,
        isFollowing.value,
      );
    }
    if (Get.isRegistered<MapController>()) {
      Get.find<MapController>().syncUserFollowState(
        targetUserId,
        isFollowing.value,
      );
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
        Get.find<DashboardController>().syncFollowFromExternal(
          targetUserId,
          isFollowing.value,
        );
      }
      if (Get.isRegistered<MapController>()) {
        Get.find<MapController>().syncUserFollowState(
          targetUserId,
          isFollowing.value,
        );
      }
      CustomAlert.showError('action_failed'.tr);
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
    // Sync về DashboardController & MapController để khi quay lại state nhất quán
    _syncLikeToExternal(
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
      _syncLikeToExternal(postId, isLiked, currentCount);
    }
  }

  void _syncLikeToExternal(String postId, bool isLiked, int count) {
    if (Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      dash.likedState(postId).value = isLiked;
      dash.likeCount(postId).value = count;
    }
    if (Get.isRegistered<MapController>()) {
      Get.find<MapController>().syncPostLikeState(postId, isLiked, count);
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

  void _applyLocalPostContentUpdate(String postId, String newContent) {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      posts[idx] = posts[idx].copyWith(content: newContent);
    }
  }

  void _applyLocalPostDelete(String postId) {
    posts.removeWhere((p) => p.id == postId);
    _likedStates.remove(postId);
    _likeCounts.remove(postId);
    _calculateTotalLikes();
  }

  /// Mở Bottom Sheet chỉnh sửa nội dung bài viết (giữ nguyên thời gian và các trường khác)
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

          // Cập nhật tại chỗ và đồng bộ sang các màn hình khác
          final ownerId = post.userId ?? targetUserId;
          syncExternalPostUpdated(ownerId, postId, newContent);
          _applyLocalPostContentUpdate(postId, newContent);

          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().syncPostContentUpdated(
              postId,
              newContent,
            );
          }
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

  /// Hiển thị hộp thoại xác nhận trước khi xóa bài viết
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

  /// Gọi API xóa bài viết và đồng bộ danh sách
  Future<void> deletePost(TrafficPostModel post) async {
    final postId = post.id;
    if (postId == null || postId.isEmpty) return;

    try {
      await _postRepository.deletePost(postId);

      final ownerId = post.userId ?? targetUserId;
      syncExternalPostDeleted(ownerId, postId);
      _applyLocalPostDelete(postId);

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().syncPostDeleted(postId);
      }
      if (Get.isRegistered<MapController>()) {
        Get.find<MapController>().syncPostDeleted(postId);
      }

      CustomAlert.showSuccess('post_delete_success'.tr);
    } catch (e) {
      CustomAlert.showError(e.toString());
    }
  }
}
