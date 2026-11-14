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

  // Khởi tạo Firebase (Bỏ qua trên Web nếu chưa cấu hình FirebaseOptions cho Web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint("Firebase init error: $e");
    }
  }

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Dotenv load warning: $e");
  }

  // Initialize localization
  await LocalizationService.init();

  // Initialize StorageService trước vì các service/repo sau có thể cần
  final storageService = await Get.putAsync(() => StorageService().init());

  // Initialize AssetsService (preload animations)
  await Get.putAsync(() => AssetsService().init());

  // Initialize ImagePickerService
  await Get.putAsync(() => ImagePickerService().init());

  // Khởi tạo NotificationService
  try {
    await Get.putAsync(() => NotificationService().init());
  } catch (e) {
    debugPrint("NotificationService init warning on web: $e");
  }

  // Check auto login
  String initialRoute = AppPages.INITIAL;

  if (kIsWeb || DemoConfig.isDemoMode) {
    await storageService.setToken('demo_token_web_static');
    await storageService.saveUserInfo(
      userId: 1,
      username: 'demo_user',
      fullname: 'Người dùng Demo',
      province: 'Hà Nội',
      relativePhone: '0988888888',
      phoneNumber: '0983168888',
      avatarUrl: DemoConfig.demoUserAvatar,
      reputationScore: 125,
      badge: 'Chuyên gia giao thông',
      canCreatePost: true,
    );
    // Khởi tạo dịch vụ mô phỏng giao thông thời gian thực cho Web Demo
    Get.put(TrafficSimulatorService());
    initialRoute = Routes.HOME;
  } else {
    final credentials = storageService.getCredentials();

    if (credentials != null) {
      try {
        final authRepository = AuthRepository();
        final loginResponse = await authRepository
            .login(
              LoginRequest(
                username: credentials['username'] ?? '',
                password: credentials['password'] ?? '',
              ),
            )
            .timeout(const Duration(seconds: 8));

        // Save user information
        await storageService.saveUserInfo(
          userId: loginResponse.id,
          username: loginResponse.username,
          fullname: loginResponse.fullname,
          province: loginResponse.province,
          relativePhone: loginResponse.relativePhone,
          phoneNumber: loginResponse.phoneNumber,
          reputationScore: loginResponse.reputationScore,
          badge: loginResponse.badge,
          canCreatePost: loginResponse.canCreatePost,
        );

        initialRoute = Routes.HOME;
      } catch (e) {
        debugPrint("Auto login failed: $e");
        final errStr = e.toString();
        if (errStr.contains('Đăng nhập thất bại') ||
            errStr.contains('401') ||
            errStr.contains('400')) {
          await storageService.clearCredentials();
        }
      }
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
          unknownRoute: GetPage(name: '/404', page: () => const NotFoundPage()),
          translations: LocalizationService(),
          locale: LocalizationService.locale,
          fallbackLocale: LocalizationService.fallbackLocale,
        );
      },
    );
  }
}
