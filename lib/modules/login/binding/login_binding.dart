import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(() => AuthRepository());

    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
  }
}
