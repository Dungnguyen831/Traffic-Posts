import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'data/models/login_request.dart';
import 'data/repositories/auth_repository.dart';
import 'modules/not_found/not_found_page.dart';
import 'routes/app_pages.dart';
import 'services/assets_service.dart';
import 'services/image_picker_service.dart';
import 'services/localization_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

// Global navigator key for showing dialogs without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo song song các tác vụ độc lập lúc mở app
  await Future.wait([
    Firebase.initializeApp(),
    dotenv.load(fileName: ".env"),
    LocalizationService.init(),
  ]);

  // Đăng ký background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize StorageService trước vì các service/repo sau có thể cần
  final storageService = await Get.putAsync(() => StorageService().init());

  // Khởi tạo song song các GetxService nền
  await Future.wait([
    Get.putAsync(() => AssetsService().init()),
    Get.putAsync(() => ImagePickerService().init()),
    Get.putAsync(() => NotificationService().init()),
  ]);

  // Check auto login
  String initialRoute = AppPages.INITIAL;
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
      // Nếu đã có token và thông tin user hợp lệ từ phiên trước mà chỉ lỗi mạng tạm thời,
      // không xóa mất credentials trừ khi xác thực thất bại
      final errStr = e.toString();
      if (errStr.contains('Đăng nhập thất bại') ||
          errStr.contains('401') ||
          errStr.contains('400')) {
        await storageService.clearCredentials();
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
      designSize: const Size(
        428,
        926,
      ), // Design size from Figma (iPhone 13 Pro Max approx)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
          title: 'Traffic App',
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
