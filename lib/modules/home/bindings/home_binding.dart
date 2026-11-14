import 'package:get/get.dart';

import '../../../data/services/sos_stream_service.dart';
import '../../camera/controllers/camera_controller.dart';
import '../../chatbot/controllers/chatbot_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../../emergency/controllers/emergency_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<MapController>(() => MapController());
    Get.lazyPut<CameraController>(() => CameraController());
    Get.lazyPut<DiscoveryController>(() => DiscoveryController());
    Get.lazyPut<ChatbotController>(() => ChatbotController());

    // SosStreamService permanent: quản lý SSE stream xuyên suốt vòng đời Home
    Get.put<SosStreamService>(SosStreamService(), permanent: true);

    // ProfileController được đăng ký permanent để giữ dữ liệu khi navigate
    Get.put<ProfileController>(ProfileController(), permanent: true);

    // EmergencyController permanent: quản lý trạng thái SOS xuyên suốt ứng dụng
    Get.put<EmergencyController>(EmergencyController(), permanent: true);
  }
}
