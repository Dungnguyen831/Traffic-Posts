import 'dart:async';
import 'package:get/get.dart';
import '../config/demo_config.dart';
import '../data/models/traffic_post_model.dart';

/// Dịch vụ mô phỏng dữ liệu giao thông cho Web Demo (đã tắt thông báo tự động)
class TrafficSimulatorService extends GetxService {
  static TrafficSimulatorService get to => Get.find<TrafficSimulatorService>();

  /// Tọa độ vị trí cố định của người dùng (Web Demo)
  final currentVehicleLocation = DemoConfig.defaultCenter.obs;

  /// Stream Controller cho các sự kiện giao thông
  final _eventStreamController = StreamController<TrafficPostModel>.broadcast();
  Stream<TrafficPostModel> get trafficEventsStream =>
      _eventStreamController.stream;

  @override
  void onClose() {
    stopSimulation();
    _eventStreamController.close();
    super.onClose();
  }

  void startSimulation() {
    // Không chạy bộ đếm gửi thông báo demo
  }

  void stopSimulation() {
    // Không sử dụng bộ đếm thông báo demo
  }
}
