import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/user_info_model.dart';
import '../../../data/repositories/follow_repository.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/custom_alert.dart';
import '../views/user_profile_screen.dart';

class FollowManagementController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final FollowRepository _followRepository = FollowRepository();
  final StorageService _storageService = Get.find<StorageService>();

  late final TabController tabController;
  final TextEditingController searchController = TextEditingController();

  final followers = <UserInfoModel>[].obs;
  final followings = <UserInfoModel>[].obs;

  final isLoadingFollowers = false.obs;
  final isLoadingFollowings = false.obs;
  final searchKeyword = ''.obs;

  // Set lưu danh sách userId mà user hiện tại đang theo dõi
  final followingIds = <int>{}.obs;

  int? get currentUserId => _storageService.getUserId();

  @override
  void onInit() {
    super.onInit();
    final initialIndex = (Get.arguments?['initialIndex'] as int?) ?? 0;
    tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex.clamp(0, 1),
    );

    searchController.addListener(() {
      searchKeyword.value = searchController.text.trim().toLowerCase();
    });

    fetchAllData();
  }

  @override
  void onClose() {
    tabController.dispose();
    searchController.dispose();
    super.onClose();
  }

  /// Tải đồng thời cả danh sách Followers và Followings
  Future<void> fetchAllData() async {
    await Future.wait([
      fetchFollowers(),
      fetchFollowings(),
    ]);
  }

  /// Lấy danh sách người theo dõi mình
  Future<void> fetchFollowers() async {
    try {
      isLoadingFollowers.value = true;
      final result = await _followRepository.getFollowers();
      followers.assignAll(result);
    } catch (e) {
      debugPrint('[FollowManagement] Lỗi tải followers: $e');
    } finally {
      isLoadingFollowers.value = false;
    }
  }

  /// Lấy danh sách những người mình đang theo dõi
  Future<void> fetchFollowings() async {
    try {
      isLoadingFollowings.value = true;
      final result = await _followRepository.getFollowings();
      followings.assignAll(result);

      // Cập nhật tập hợp followingIds
      final ids = result.map((u) => u.id).whereType<int>().toSet();
      followingIds.assignAll(ids);
    } catch (e) {
      debugPrint('[FollowManagement] Lỗi tải followings: $e');
    } finally {
      isLoadingFollowings.value = false;
    }
  }

  /// Kiểm tra xem hiện tại mình có đang theo dõi userId này hay không
  bool isFollowing(int? userId) {
    if (userId == null) return false;
    return followingIds.contains(userId);
  }

  /// Tương tác Follow / Unfollow
  Future<void> toggleFollow(UserInfoModel user) async {
    final userId = user.id;
    if (userId == null || userId == currentUserId) return;

    final wasFollowing = followingIds.contains(userId);

    // Optimistic Update: Cập nhật giao diện ngay lập tức
    if (wasFollowing) {
      followingIds.remove(userId);
    } else {
      followingIds.add(userId);
    }

    try {
      await _followRepository.followUser(userId);
      CustomAlert.showSuccess(
        wasFollowing
            ? 'Đã bỏ theo dõi ${user.fullname ?? user.username ?? "người dùng"}'
            : 'Đã theo dõi ${user.fullname ?? user.username ?? "người dùng"}',
      );
    } catch (e) {
      // Rollback trạng thái nếu API lỗi
      if (wasFollowing) {
        followingIds.add(userId);
      } else {
        followingIds.remove(userId);
      }
      CustomAlert.showError('Thao tác không thành công: $e');
    }
  }

  /// Danh sách người theo dõi đã lọc theo từ khóa tìm kiếm
  List<UserInfoModel> get filteredFollowers {
    final query = searchKeyword.value;
    if (query.isEmpty) return followers;
    return followers.where((u) {
      final name = (u.fullname ?? '').toLowerCase();
      final username = (u.username ?? '').toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  /// Danh sách đang theo dõi đã lọc theo từ khóa tìm kiếm
  List<UserInfoModel> get filteredFollowings {
    final query = searchKeyword.value;
    if (query.isEmpty) return followings;
    return followings.where((u) {
      final name = (u.fullname ?? '').toLowerCase();
      final username = (u.username ?? '').toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  /// Bấm trực tiếp vào người dùng để chuyển đến trang cá nhân của họ
  void openUserProfile(UserInfoModel user) {
    if (user.id == null) return;
    Get.to(
      () => const UserProfileScreen(),
      arguments: {
        'userId': user.id,
        'initialAvatarUrl': user.fullAvatarUrl,
        'initialUserName': user.fullname ?? user.username,
      },
      preventDuplicates: false,
    );
  }

  void clearSearch() {
    searchController.clear();
    searchKeyword.value = '';
  }
}
