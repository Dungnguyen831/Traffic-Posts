import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class AssetsService extends GetxService {
  static AssetsService get to => Get.find();

  final Rx<LottieComposition?> notFoundComposition = Rx<LottieComposition?>(
    null,
  );
  final Rx<LottieComposition?> loadingComposition = Rx<LottieComposition?>(
    null,
  );
  final Rx<LottieComposition?> closeComposition = Rx<LottieComposition?>(null);

  Future<void> init() async {
    // Trên Web, không block main bằng việc load đồng bộ Lottie
    if (kIsWeb) return;
    try {
      notFoundComposition.value = await AssetLottie(
        'assets/animations/404_not_found.json',
      ).load();
      loadingComposition.value = await AssetLottie(
        'assets/animations/Loading.json',
      ).load();
      closeComposition.value = await AssetLottie(
        'assets/animations/Close.json',
      ).load();
    } catch (e) {
      debugPrint('Error preloading assets: $e');
    }
  }
}
