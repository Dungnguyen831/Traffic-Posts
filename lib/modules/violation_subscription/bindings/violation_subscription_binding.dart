import 'package:get/get.dart';

import '../controllers/violation_subscription_controller.dart';

class ViolationSubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ViolationSubscriptionController>(
      () => ViolationSubscriptionController(),
    );
  }
}
