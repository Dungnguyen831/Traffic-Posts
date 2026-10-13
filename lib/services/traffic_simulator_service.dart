import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../config/demo_config.dart';
import '../data/models/location_model.dart';
import '../data/models/sos_model.dart';
import '../data/models/traffic_post_model.dart';
import '../data/repositories/traffic_post_repository.dart';
import '../data/services/sos_stream_service.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/map/controllers/map_controller.dart';

/// Dịch vụ mô phỏng dữ liệu & sự kiện giao thông thời gian thực cho Web Demo
class TrafficSimulatorService extends GetxService {
  static TrafficSimulatorService get to => Get.find<TrafficSimulatorService>();

  Timer? _eventSimulationTimer;

  int _poolEventIndex = 0;

  /// Tọa độ vị trí cố định của người dùng (Web Demo)
  final currentVehicleLocation = DemoConfig.defaultCenter.obs;

  /// Stream Controller để thông báo sự kiện giao thông mới
  final _eventStreamController = StreamController<TrafficPostModel>.broadcast();
  Stream<TrafficPostModel> get trafficEventsStream =>
      _eventStreamController.stream;

  @override
  void onInit() {
    super.onInit();
    if (DemoConfig.isDemoMode) {
      startSimulation();
    }
  }

  @override
  void onClose() {
    stopSimulation();
    _eventStreamController.close();
    super.onClose();
  }

  /// Bắt đầu luồng mô phỏng sự kiện định kỳ mỗi 40 giây (Vị trí giữ cố định)
  void startSimulation() {
    stopSimulation();

    // Mô phỏng sự kiện giao thông định kỳ thời gian thực (Mỗi 40 giây)
    _eventSimulationTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _generatePeriodicTrafficEvent(),
    );

    debugPrint(
      '[TrafficSimulator] 🚀 Đã kích hoạt mô phỏng Real-time (Chu kỳ 40s) Web Demo',
    );
  }

  void stopSimulation() {
    _eventSimulationTimer?.cancel();
    _eventSimulationTimer = null;
  }

  /// Tạo sự kiện giao thông giả lập mới
  void _generatePeriodicTrafficEvent() {
    final pool = DemoConfig.dynamicTrafficEventsPool;
    if (pool.isEmpty) return;

    final eventData = pool[_poolEventIndex % pool.length];
    _poolEventIndex++;

    final String tag = eventData['tag'];
    final now = DateTime.now();
    final String eventId = 'simulated_${tag}_${now.millisecondsSinceEpoch}';

    if (tag == 'sos') {
      // Phát sinh sự kiện SOS
      final newSos = SosResponseDTO(
        sosId: eventId,
        phoneNumber: '09${10000000 + (_poolEventIndex * 777) % 90000000}',
        latitude: eventData['lat'],
        longitude: eventData['lng'],
        note: eventData['content'],
        status: 'ACTIVE',
        address: eventData['address'],
        timestamp: now,
      );

      // Thêm vào SosStreamService
      if (Get.isRegistered<SosStreamService>()) {
        SosStreamService.to.sosList.insert(0, newSos);
      }

      _showSimulatedNotification(
        title: '🆘 Tín hiệu SOS Cứu hộ Mới (Mô phỏng)',
        message: '${eventData['content']} - ${eventData['address']}',
        color: Colors.pinkAccent.shade700,
        icon: Icons.emergency,
      );
    } else {
      // Phát sinh sự kiện bài đăng giao thông (ketxe, tainan, ngaplutnuoc) kèm ảnh mô phỏng
      final newPost = TrafficPostModel(
        id: eventId,
        userId: 'sim_$_poolEventIndex',
        userName: eventData['userName'] ?? 'Người tham gia giao thông',
        avatarUrl: eventData['avatarUrl'],
        content: eventData['content'],
        hashtags: [tag],
        imageUrls: eventData['imageUrls'] != null
            ? List<String>.from(eventData['imageUrls'])
            : null,
        location: LocationModel(
          lat: eventData['lat'],
          lng: eventData['lng'],
          address: eventData['address'],
        ),
        likes: 1,
        isLiked: false,
        timestamp: now,
      );

      _eventStreamController.add(newPost);

      // 1. Thêm trực tiếp vào bản đồ MapController
      if (Get.isRegistered<MapController>()) {
        Get.find<MapController>().addDynamicPost(newPost);
      }

      // 2. Thêm vào bảng tin DashboardController nếu đang mở và lưu vào cache repository
      TrafficPostRepository.addDemoPost(newPost);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().prependPost(newPost);
      }

      // 3. Hiển thị thông báo Real-time cho người dùng thấy sự kiện vừa xuất hiện
      Color alertColor;
      IconData alertIcon;
      String eventTypeName;

      switch (tag) {
        case 'ketxe':
          alertColor = Colors.red.shade700;
          alertIcon = Icons.traffic;
          eventTypeName = 'Cảnh báo Ùn tắc';
          break;
        case 'tainan':
          alertColor = Colors.deepOrange.shade700;
          alertIcon = Icons.warning_amber_rounded;
          eventTypeName = 'Sự cố / Tai nạn';
          break;
        case 'ngaplutnuoc':
          alertColor = Colors.cyan.shade800;
          alertIcon = Icons.water_drop;
          eventTypeName = 'Cảnh báo Ngập lụt';
          break;
        default:
          alertColor = const Color(0xFF4D5DFA);
          alertIcon = IconlyBold.notification;
          eventTypeName = 'Thông tin Giao thông';
      }

      _showSimulatedNotification(
        title: '🚨 [$eventTypeName] #${tag.toUpperCase()}',
        message: '${eventData['content']}\n📍 ${eventData['address']}',
        color: alertColor,
        icon: alertIcon,
      );
    }
  }

  void _showSimulatedNotification({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    // Chỉ hiển thị toast thông báo nếu Get context đã sẵn sàng
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        backgroundColor: color.withOpacity(0.92),
        colorText: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        icon: Icon(icon, color: Colors.white, size: 28),
        boxShadows: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }
}
