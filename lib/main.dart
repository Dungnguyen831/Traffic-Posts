import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'config/demo_config.dart';
import 'data/models/login_request.dart';
import 'data/repositories/auth_repository.dart';
import 'modules/not_found/not_found_page.dart';
import 'routes/app_pages.dart';
import 'services/assets_service.dart';
import 'services/image_picker_service.dart';
import 'services/localization_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/traffic_simulator_service.dart';
import 'theme/app_theme.dart';

// Global navigator key for showing dialogs without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Hỗ trợ thao tác kéo cuộn chuột mượt mà trên trình duyệt Web Desktop
class WebAppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase chỉ khởi tạo trên Native Mobile (bỏ qua hoàn toàn trên Web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  // 2. Load .env an toàn
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('.env load warning: $e');
  }

  // 3. Khởi tạo Localization an toàn
  try {
    await LocalizationService.init();
  } catch (e) {
    debugPrint('LocalizationService init warning: $e');
  }

  // 4. Khởi tạo StorageService an toàn
  late StorageService storageService;
  try {
    storageService = await Get.putAsync(() => StorageService().init());
  } catch (e) {
    debugPrint('StorageService init error: $e');
    storageService = Get.put(StorageService());
  }

  // 5. Khởi tạo AssetsService an toàn (tránh đơ main)
  try {
    if (!kIsWeb) {
      await Get.putAsync(
        () => AssetsService().init().then((_) => AssetsService()),
      );
    } else {
      Get.put(AssetsService());
    }
  } catch (e) {
    debugPrint('AssetsService init error: $e');
    Get.put(AssetsService());
  }

  // 6. Khởi tạo ImagePickerService an toàn
  try {
    await Get.putAsync(() => ImagePickerService().init());
  } catch (e) {
    debugPrint('ImagePickerService init error: $e');
    Get.put(ImagePickerService());
  }

  // 7. Khởi tạo NotificationService an toàn (bỏ qua Native FCM trên Web)
  try {
    if (!kIsWeb) {
      await Get.putAsync(() => NotificationService().init());
    } else {
      final noti = NotificationService();
      noti.fcmToken.value = 'demo_web_fcm_token';
      Get.put(noti);
    }
  } catch (e) {
    debugPrint('NotificationService init error: $e');
    final noti = NotificationService();
    noti.fcmToken.value = 'demo_web_fcm_token';
    Get.put(noti);
  }

  // 8. Xử lý khởi động: Tự động kích hoạt Web Demo
  String initialRoute = Routes.HOME;

  if (kIsWeb || DemoConfig.isDemoMode) {
    // Luôn đảm bảo tài khoản demo đã được lưu để app coi như đã đăng nhập
    try {
      await storageService.saveUserInfo(
        username: 'Dung',
        fullname: 'Nguyễn Anh Dũng',
        province: 'Hà Nội',
        relativePhone: '0987654321',
        phoneNumber: '0912345678',
      );
      await storageService.setToken('demo_access_token');
    } catch (e) {
      debugPrint('Storage demo user save error: $e');
    }

    // Khởi tạo Stream/Timer giả lập sự kiện giao thông và di chuyển xe
    try {
      Get.put(TrafficSimulatorService());
    } catch (e) {
      debugPrint('TrafficSimulatorService register error: $e');
    }

    // Điều hướng thẳng vào màn hình Map / Dashboard chính
    initialRoute = Routes.HOME;
  } else {
    // Trên Native Mobile: Kiểm tra auto login bình thường
    initialRoute = AppPages.INITIAL;
    try {
      final credentials = storageService.getCredentials();
      if (credentials != null) {
        final authRepository = AuthRepository();
        final loginResponse = await authRepository.login(
          LoginRequest(
            username: credentials['username'] ?? '',
            password: credentials['password'] ?? '',
          ),
        );

        // Save user information
        await storageService.saveUserInfo(
          username: loginResponse.username,
          fullname: loginResponse.fullname,
          province: loginResponse.province,
          relativePhone: loginResponse.relativePhone,
        );

        initialRoute = Routes.HOME;
      }
    } catch (e) {
      debugPrint("Auto login failed: $e");
      try {
        await storageService.clearCredentials();
      } catch (_) {}
    }
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(428, 926), // iPhone 13 Pro Max approx
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          scrollBehavior: WebAppScrollBehavior(),
          navigatorKey: navigatorKey,
          title: 'Traffic App - Web Demo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: initialRoute,
          getPages: AppPages.routes,
          unknownRoute: GetPage(name: '/404', page: () => NotFoundPage()),
          translations: LocalizationService(),
          locale: LocalizationService.locale,
          fallbackLocale: LocalizationService.fallbackLocale,
        );
      },
    );
  }
}
