import 'package:get/get.dart';
import '../controllers/emergency_controller.dart';

class EmergencyBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EmergencyController>()) {
      Get.lazyPut<EmergencyController>(() => EmergencyController());
    }
  }
}