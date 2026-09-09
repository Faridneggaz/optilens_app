import 'package:get/get.dart';
import '../../application/controllers/login_controller.dart';
import '../../core/network/api_client.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/login_repository.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginRepository>(
      () => LoginRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<LoginController>(
      () => LoginController(
        loginRepo: Get.find<LoginRepository>(),
        customerRepo: Get.find<CustomerRepository>(),
      ),
    );
  }
}
