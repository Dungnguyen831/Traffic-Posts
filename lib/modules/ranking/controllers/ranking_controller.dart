import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/user_info_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../widgets/custom_alert.dart';

class RankingController extends GetxController {
  final UserRepository _userRepository = UserRepository();
  final ScrollController scrollController = ScrollController();

  final rankingList = <UserInfoModel>[].obs;
  final isLoading = true.obs;
  final isLoadMore = false.obs;
  final hasMore = true.obs;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    _setupScrollListener();
    fetchRanking(isRefresh: true);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !isLoading.value &&
          !isLoadMore.value &&
          hasMore.value) {
        loadMore();
      }
    });
  }

  Future<void> fetchRanking({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 0;
      hasMore.value = true;
      isLoading.value = true;
    }

    try {
      final list = await _userRepository.getRanking(
        page: _currentPage,
        size: _pageSize,
      );

      if (isRefresh) {
        rankingList.assignAll(list);
      } else {
        rankingList.addAll(list);
      }

      if (list.length < _pageSize) {
        hasMore.value = false;
      }
    } catch (e) {
      CustomAlert.showError(e.toString());
    } finally {
      isLoading.value = false;
      isLoadMore.value = false;
    }
  }

  Future<void> onRefresh() async {
    await fetchRanking(isRefresh: true);
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadMore.value || !hasMore.value) return;
    isLoadMore.value = true;
    _currentPage++;
    try {
      final list = await _userRepository.getRanking(
        page: _currentPage,
        size: _pageSize,
      );

      if (list.isEmpty || list.length < _pageSize) {
        hasMore.value = false;
      }
      rankingList.addAll(list);
    } catch (e) {
      hasMore.value = false;
    } finally {
      isLoadMore.value = false;
    }
  }
}
