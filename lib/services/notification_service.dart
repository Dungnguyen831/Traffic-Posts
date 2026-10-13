import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../config/demo_config.dart';

/// Background message handler — phải là top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 [BG] Nhận message: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body:  ${message.notification?.body}');
  debugPrint('   Data:  ${message.data}');
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  FirebaseMessaging? _messaging;
  final RxString fcmToken = ''.obs;

  Future<NotificationService> init() async {
    if (kIsWeb || DemoConfig.isDemoMode) {
      fcmToken.value = 'demo_web_fcm_token';
      debugPrint('🔔 [NotificationService] Web Demo Mode: FCM bypassed.');
      return this;
    }

    try {
      _messaging = FirebaseMessaging.instance;

      // Xin quyền notification (iOS)
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

      // Lấy FCM token — quan trọng để test trên Simulator
      await _refreshToken();

      // Lắng nghe token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        fcmToken.value = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
      });

      // Foreground message handler (app đang mở)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // App mở từ notification (background → foreground)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // App mở từ terminated state qua notification
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 App opened from terminated via notification');
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }

    return this;
  }

  Future<void> _refreshToken() async {
    if (kIsWeb || _messaging == null) return;
    try {
      final token = await _messaging?.getToken();
      if (token != null) {
        fcmToken.value = token;
        debugPrint('✅ FCM Token (dùng để test trên Firebase Console):');
        debugPrint('   $token');
      }
    } catch (e) {
      debugPrint('❌ Lỗi lấy FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 [FG] Nhận message: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body:  ${message.notification?.body}');
    debugPrint('   Data:  ${message.data}');

    // Hiển thị SnackBar khi app đang foreground
    final title =
        message.notification?.title ?? message.data['title'] ?? 'Thông báo';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFF4D5DFA).withOpacity(0.95),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(IconlyBold.notification, color: Colors.white),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 User tapped notification: ${message.data}');
    // TODO: Navigate theo message.data['route'] nếu cần
    // Ví dụ: if (message.data['route'] == 'home') Get.toNamed(Routes.HOME);
  }
}
