import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class AssetsService extends GetxService {
  static AssetsService get to => Get.find<AssetsService>();

  final Rx<LottieComposition?> notFoundComposition = Rx<LottieComposition?>(
    null,
  );
  final Rx<LottieComposition?> loadingComposition = Rx<LottieComposition?>(
    null,
  );
  final Rx<LottieComposition?> closeComposition = Rx<LottieComposition?>(null);

  List<Map<String, dynamic>>? _cachedProvinces;
  Future<List<Map<String, dynamic>>>? _provincesFuture;

  Future<AssetsService> init() async {
    // Preload critical animations in parallel
    try {
      final results = await Future.wait([
        AssetLottie('assets/animations/404_not_found.json').load(),
        AssetLottie('assets/animations/Loading.json').load(),
        AssetLottie('assets/animations/Close.json').load(),
      ]);
      notFoundComposition.value = results[0];
      loadingComposition.value = results[1];
      closeComposition.value = results[2];
    } catch (e) {
      debugPrint('Error preloading assets: $e');
    }
    return this;
  }

  /// Đọc và cache danh sách Tỉnh/Thành phố dùng chung cho toàn ứng dụng
  Future<List<Map<String, dynamic>>> getProvinces() {
    if (_cachedProvinces != null) {
      return Future.value(_cachedProvinces!);
    }
    _provincesFuture ??= _loadProvincesFromBundle();
    return _provincesFuture!;
  }

  Future<List<Map<String, dynamic>>> _loadProvincesFromBundle() async {
    try {
      final response = await rootBundle.loadString('assets/json/provinces.json');
      final List<dynamic> data = json.decode(response);
      _cachedProvinces = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
      return _cachedProvinces!;
    } catch (e) {
      debugPrint('Error loading provinces: $e');
      _provincesFuture = null;
      return const [];
    }
  }
}
