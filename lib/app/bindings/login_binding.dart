import 'package:get/get.dart';
import '../../presentation/controllers/login_controller.dart';
import '../../domain/usecases/usecases.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(auth: Get.find<AuthUseCases>()),
    );
  }
}
