import 'package:get/get.dart';
import '../../data/repositories/payment_repository.dart';
import '../../utils/payment_utils.dart';
import 'session_controller.dart';

class PaymentController extends GetxController {
  final _repo = PaymentRepository();

  final payments  = <PaymentItemData>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    final code = Get.find<SessionController>().customer.value?.code ?? '';
    loadPayments(code);
  }

  Future<void> loadPayments(String customerCode) async {
    isLoading.value = true;
    try {
      final response = await _repo.fetchPayments(customerCode);
      payments.value = response.payments.map((p) {
        return PaymentItemData(
          paymentId: p.name,
          date: p.posting_date,
          invoices: p.invoices_payed
              .map((inv) => PaidInvoice(
                    invoiceId: inv.invoice,
                    amount: inv.allocated_amount,
                  ))
              .toList(),
        );
      }).toList();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
