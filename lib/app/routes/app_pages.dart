import 'package:get/get.dart';

import '../../views/client/about_j_optic_screen.dart';
import '../../views/client/about_page.dart';
import '../../views/client/announcement_detail_view.dart';
import '../../views/client/change_password_page.dart';
import '../../views/client/complaint_form_view.dart';
import '../../views/client/invoice_detail_page.dart';
import '../../views/client/login_view.dart';
import '../../views/client/notifications_page.dart';
import '../../views/client/order_history_page.dart';
import '../../views/client/order_page.dart';
import '../../widgets/zoom_drawer_page.dart';
import '../../views/user/material_request_detail_page.dart';
import '../../views/user/material_request_page.dart';
import '../../views/user/stock_entry.dart';
import '../../views/user/task_detail_page.dart';
import '../../views/user/tasks_page.dart';
import '../../views/user/job_profile_page.dart';
import '../../views/manque/commande_manque_list_page.dart';
import '../../views/manque/commande_manque_form_page.dart';
import '../../views/manque/commande_manque_detail_page.dart';
import '../../views/manque/facture_acheteur_list_page.dart';
import '../../views/manque/facture_acheteur_form_page.dart';
import '../bindings/app_binding.dart';
import '../bindings/feature_bindings.dart';
import '../bindings/login_binding.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const ZoomDrawerPage(),
      binding: AppBinding(),
    ),
    GetPage(
      name: AppRoutes.invoiceDetail,
      page: () => const InvoiceDetailPage(),
      binding: InvoiceDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.orderHistory,
      page: () => const OrderHistoryPage(),
      binding: OrderHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.order,
      page: () => const OrderPage(),
      binding: OrderBinding(),
    ),
    GetPage(
      name: AppRoutes.complaint,
      page: () => const ComplaintFormPage(),
      binding: ComplaintBinding(),
    ),
    GetPage(
      name: AppRoutes.announcementDetail,
      page: () => const AnnouncementDetailPage(),
    ),
    GetPage(
      name: AppRoutes.stockEntry,
      page: () => const StockEntryPage(),
      binding: StockEntryDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordPage(),
      binding: ChangePasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.about,
      page: () => const AboutPage(),
    ),
    GetPage(
      name: AppRoutes.aboutJoptic,
      page: () => const AboutJethingsScreen(),
      binding: AboutJopticBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: AppRoutes.materialRequests,
      page: () => const MaterialRequestPage(),
      binding: MaterialRequestBinding(),
    ),
    GetPage(
      name: AppRoutes.materialRequestDetail,
      page: () => const MaterialRequestDetailPage(),
      binding: MaterialRequestDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.tasks,
      page: () => const TasksPage(),
      binding: TaskBinding(),
    ),
    GetPage(
      name: AppRoutes.taskDetail,
      page: () => const TaskDetailPage(),
      binding: TaskDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.jobProfile,
      page: () => const JobProfilePage(),
      binding: JobProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.commandesManque,
      page: () => const CommandeManqueListPage(),
      binding: CommandeManqueBinding(),
    ),
    GetPage(
      name: AppRoutes.commandeManqueForm,
      page: () => const CommandeManqueFormPage(),
      binding: CommandeManqueBinding(),
    ),
    GetPage(
      name: AppRoutes.facturesAcheteur,
      page: () => const FactureAcheteurListPage(),
      binding: FactureAcheteurBinding(),
      preventDuplicates: false,
    ),
    GetPage(
      name: AppRoutes.factureAcheteurForm,
      page: () => const FactureAcheteurFormPage(),
      binding: FactureAcheteurFormBinding(),
      preventDuplicates: false,
    ),
    GetPage(
      name: AppRoutes.commandeManqueDetail,
      page: () => const CommandeManqueDetailPage(),
      binding: CommandeManqueDetailBinding(),
      preventDuplicates: false,
    ),
  ];
}
