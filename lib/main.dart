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
  await Firebase.initializeApp();

  // Đăng ký background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: ".env");
  await LocalizationService.init();

  // Initialize StorageService
  final storageService = await Get.putAsync(() => StorageService().init());

  // Initialize AssetsService
  await Get.putAsync(() => AssetsService().init().then((_) => AssetsService()));

  // Initialize ImagePickerService (warms up the picker platform channel)
  await Get.putAsync(() => ImagePickerService().init());

  // Initialize NotificationService (FCM)
  await Get.putAsync(() => NotificationService().init());

  // Check auto login
  String initialRoute = AppPages.INITIAL;
  final credentials = storageService.getCredentials();

  if (credentials != null) {
    try {
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
    } catch (e) {
      // Login failed, stay at LOGIN
      debugPrint("Auto login failed: $e");
      // Nếu lỗi thì xóa credentials đi để lần sau không tự login sai nữa
      await storageService.clearCredentials();
    }
  }

  // String initialRoute = Routes.HOME;
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
          unknownRoute: GetPage(name: '/404', page: () => NotFoundPage()),
          translations: LocalizationService(),
          locale: LocalizationService.locale,
          fallbackLocale: LocalizationService.fallbackLocale,
        );
      },
    );
  }
}
