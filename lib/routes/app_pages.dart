import 'package:get/get.dart';

import '../modules/camera/bindings/camera_binding.dart';
import '../modules/camera/views/camera_view.dart';
import '../modules/emergency/bindings/emergency_binding.dart';
import '../modules/emergency/controllers/sos_stream_controller.dart';
import '../modules/emergency/views/emergency_screen.dart';
import '../modules/emergency/views/sos_stream_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/binding/login_binding.dart';
import '../modules/login/views/login_screen.dart';
import '../modules/profile/bindings/follow_management_binding.dart';
import '../modules/profile/views/follow_management_view.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/ranking/bindings/ranking_binding.dart';
import '../modules/ranking/views/ranking_view.dart';
import '../modules/signup/bindings/signup_binding.dart';
import '../modules/signup/views/signup_screen.dart';
import '../modules/violation_subscription/bindings/violation_subscription_binding.dart';
import '../modules/violation_subscription/views/violation_subscription_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.SIGNUP,
      page: () => const SignupScreen(),
      binding: SignupBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      // Không cần binding vì ProfileController đã được đăng ký permanent trong HomeBinding
    ),
    GetPage(
      name: _Paths.CAMERA,
      page: () => const CameraView(),
      binding: CameraBinding(),
    ),
    GetPage(
      name: _Paths.EMERGENCY,
      page: () => const EmergencyScreen(),
      binding: EmergencyBinding(),
    ),
    GetPage(
      name: _Paths.SOS_STREAM,
      page: () => const SosStreamView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SosStreamController>(() => SosStreamController());
      }),
    ),
    GetPage(
      name: _Paths.VIOLATION_SUBSCRIPTION,
      page: () => const ViolationSubscriptionView(),
      binding: ViolationSubscriptionBinding(),
    ),
    GetPage(
      name: _Paths.RANKING,
      page: () => const RankingView(),
      binding: RankingBinding(),
    ),
    GetPage(
      name: _Paths.FOLLOW_MANAGEMENT,
      page: () => const FollowManagementView(),
      binding: FollowManagementBinding(),
    ),
  ];
}
