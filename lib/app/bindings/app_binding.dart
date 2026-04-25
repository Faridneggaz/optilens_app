import 'package:get/get.dart';
import '../../application/controllers/main_controller.dart';
import '../../application/controllers/user_dashboard_controller.dart';
import '../../application/controllers/dashboard_controller.dart';
import '../../application/controllers/invoice_controller.dart';
import '../../application/controllers/payment_controller.dart';
import '../../application/controllers/complaint_controller.dart';
import '../../application/controllers/order_controller.dart';
import '../../application/controllers/announcement_controller.dart';
import '../../application/controllers/stock_entry_controller.dart';

/// Registers all feature controllers for the /main route.
/// InvoiceDetailController and StockEntryDetailsController are intentionally
/// excluded here — they are registered fresh per-push via BindingsBuilder
/// in GetPage definitions so each detail page always gets clean state.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Shared by both client and user mode
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<OrderController>(() => OrderController());

    // Client-mode only (never instantiated if user is in user mode)
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<InvoiceController>(() => InvoiceController());
    Get.lazyPut<PaymentController>(() => PaymentController());
    Get.lazyPut<ComplaintController>(() => ComplaintController());
    Get.lazyPut<AnnouncementController>(() => AnnouncementController());

    // User-mode only (never instantiated if user is in client mode)
    Get.lazyPut<UserDashboardController>(() => UserDashboardController());
    Get.lazyPut<StockEntryController>(() => StockEntryController());
  }
}
