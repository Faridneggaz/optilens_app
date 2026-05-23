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
import 'views/client/change_password_page.dart';
import 'views/client/about_page.dart';
import 'views/user/stock_entry.dart';
import 'views/user/material_request_page.dart';
import 'views/user/material_request_detail_page.dart';
import 'views/client/notifications_page.dart';
import 'widgets/zoom_drawer_page.dart';
import 'application/controllers/session_controller.dart';
import 'application/controllers/invoice_detail_controller.dart';
import 'application/controllers/change_password_controller.dart';
import 'application/controllers/notification_controller.dart';
import 'application/controllers/stock_entry_details_controller.dart';
import 'application/controllers/material_request_list_controller.dart';
import 'application/controllers/material_request_detail_controller.dart';
import 'application/controllers/order_controller.dart';
import 'application/controllers/language_controller.dart';
import 'utils/translations/app_translations.dart';
import 'core/services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Services persistants initialisés avant runApp
  await Get.putAsync(() => SessionService().init());
  Get.put(SessionController(), permanent: true);
  Get.put(LanguageController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionService = Get.find<SessionService>();
    final lc             = Get.find<LanguageController>();
    final initial = sessionService.isSessionValid()
        ? AppRoutes.main
        : AppRoutes.login;

    // ── Obx observe lc.current (Rx<AppLanguage>) ────────────────────────────
    // Quand current.value change → Obx se reconstruit → GetMaterialApp reçoit
    // la nouvelle locale → toutes les chaînes .tr sont mises à jour.
    // Get.forceAppUpdate() dans changeLanguage() force en plus le refresh
    // des pages déjà ouvertes dans le navigator.
    return Obx(() {
      final locale = lc.current.value.locale;
      final isRtl  = lc.current.value.languageCode == 'ar';

      return GetMaterialApp(
        title:                    'Optilens',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.teal),

        // ── i18n ────────────────────────────────────────────────────────────
        translations:   AppTranslations(),
        locale:         locale,
        fallbackLocale: const Locale('fr', 'FR'),

        // ── RTL pour l'arabe ─────────────────────────────────────────────────
        builder: (ctx, child) => Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),

        initialRoute: initial,
        getPages: [
          // ── Auth ────────────────────────────────────────────────────────────
          GetPage(
            name:    AppRoutes.login,
            page:    () => const LoginPage(),
            binding: LoginBinding(),
          ),

          // ── Shell principal ──────────────────────────────────────────────────
          GetPage(
            name:    AppRoutes.main,
            page:    () => const ZoomDrawerPage(),
            binding: AppBinding(),
          ),

          // ── Pages de détail ──────────────────────────────────────────────────
          GetPage(
            name:    AppRoutes.invoiceDetail,
            page:    () => const InvoiceDetailPage(),
            binding: BindingsBuilder(() { Get.put(InvoiceDetailController()); }),
          ),
          GetPage(
            name:    AppRoutes.orderHistory,
            page:    () => const OrderHistoryPage(),
            binding: BindingsBuilder(() {
              Get.put(OrderController()).loadOrders();
            }),
          ),
          GetPage(
            name:    AppRoutes.order,
            page:    () => const OrderPage(),
            binding: BindingsBuilder(() {
              Get.put(OrderController()).clearCart();
            }),
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
            binding: BindingsBuilder(() { Get.put(StockEntryDetailsController()); }),
          ),
          GetPage(
            name:    AppRoutes.changePassword,
            page:    () => const ChangePasswordPage(),
            binding: BindingsBuilder(() { Get.put(ChangePasswordController()); }),
          ),
          GetPage(
            name:    AppRoutes.about,
            page:    () => const AboutPage(),
          ),
          GetPage(
            name:    AppRoutes.notifications,
            page:    () => const NotificationsPage(),
            binding: BindingsBuilder(() { Get.lazyPut(() => NotificationController()); }),
          ),
          GetPage(
            name:    AppRoutes.materialRequests,
            page:    () => const MaterialRequestPage(),
            binding: BindingsBuilder(() { Get.lazyPut(() => MaterialRequestListController()); }),
          ),
          GetPage(
            name: AppRoutes.materialRequestDetail,
            page: () => const MaterialRequestDetailPage(),
            binding: BindingsBuilder(() {
              final name = Get.arguments as String? ?? '';
              Get.put(MaterialRequestDetailController(name));
            }),
          ),
        ],
      );
    });
  }
}