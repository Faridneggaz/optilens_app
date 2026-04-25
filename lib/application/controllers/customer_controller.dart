import 'package:get/get.dart';
import '../../data/repositories/customer_repository.dart';
import '../../domain/response/customer_response.dart';

class CustomerController extends GetxController {
  final CustomerRepository _repository = CustomerRepository();

  Future<CustomerResponse?> fetchCustomer(String code) async {
    try {
      return await _repository.fetchCustomer(code);
    } catch (_) {
      return null;
    }
  }
}
