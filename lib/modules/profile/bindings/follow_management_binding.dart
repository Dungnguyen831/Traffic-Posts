import 'package:get/get.dart';

import '../controllers/follow_management_controller.dart';

class FollowManagementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FollowManagementController>(
      () => FollowManagementController(),
    );
  }
}
