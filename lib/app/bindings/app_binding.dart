import 'package:get/get.dart';
import '../../presentation/controllers/main_controller.dart';
import '../../presentation/controllers/user_dashboard_controller.dart';
import '../../presentation/controllers/dashboard_controller.dart';
import '../../presentation/controllers/invoice_controller.dart';
import '../../presentation/controllers/payment_controller.dart';
import '../../presentation/controllers/stock_entry_controller.dart';
import '../../presentation/controllers/material_request_controller.dart';

/// Registers shell controllers for the `/main` route.
/// Per-push detail pages (invoice, stock entry, orders, etc.) use
/// dedicated bindings in [AppPages].
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());

    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<InvoiceController>(() => InvoiceController());
    Get.lazyPut<PaymentController>(() => PaymentController());

    Get.lazyPut<UserDashboardController>(() => UserDashboardController());
    Get.lazyPut<StockEntryController>(() => StockEntryController());
    Get.lazyPut<MaterialRequestController>(() => MaterialRequestController());
  }
}
