import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/login_binding.dart';
import 'app/bindings/app_binding.dart';
import 'views/client/login_view.dart';
import 'views/client/invoice_detail_page.dart';
import 'views/client/order_history_page.dart';
import 'views/client/order_page.dart';
import 'views/client/complaint_form_view.dart';
import 'views/client/announcement_detail_view.dart';
import 'views/user/stock_entry.dart';
import 'widgets/zoom_drawer_page.dart';
import 'application/controllers/session_controller.dart';
import 'application/controllers/invoice_detail_controller.dart';
import 'application/controllers/stock_entry_details_controller.dart';

void main() {
  // SessionController is permanent so it survives full route clears (logout)
  Get.put(SessionController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Optilens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: AppRoutes.login,
      getPages: [
        // ── Auth ─────────────────────────────────────────────────────────────
        GetPage(
          name:    AppRoutes.login,
          page:    () => const LoginPage(),
          binding: LoginBinding(),
        ),

        // ── Main shell (client + user) ────────────────────────────────────────
        GetPage(
          name:    AppRoutes.main,
          page:    () => const ZoomDrawerPage(),
          binding: AppBinding(),
        ),

        // ── Per-push detail pages (fresh controller each time via GetPage binding) ─
        GetPage(
          name:    AppRoutes.invoiceDetail,
          page:    () => const InvoiceDetailPage(),
          binding: BindingsBuilder(() => Get.put(InvoiceDetailController())),
        ),
        GetPage(
          name: AppRoutes.orderHistory,
          page: () => const OrderHistoryPage(),
        ),
        GetPage(
          name: AppRoutes.order,
          page: () => const OrderPage(),
        ),
        GetPage(
          name: AppRoutes.complaint,
          page: () => const ComplaintFormPage(),
        ),
        GetPage(
          name: AppRoutes.announcementDetail,
          page: () => const AnnouncementDetailPage(),
        ),
        GetPage(
          name:    AppRoutes.stockEntry,
          page:    () => const StockEntryPage(),
          binding: BindingsBuilder(() => Get.put(StockEntryDetailsController())),
        ),
      ],
    );
  }
}
