import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_detail_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/material_request_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/stock_entry_details_repository.dart';
import '../../data/repositories/stock_entry_repository.dart';

/// Registers data repositories once for the whole app lifetime.
class RepositoryBinding {
  static void register() {
    final api = Get.find<ApiClient>();
    Get.put(CustomerRepository(api), permanent: true);
    Get.put(InvoiceRepository(api), permanent: true);
    Get.put(InvoiceDetailRepository(api), permanent: true);
    Get.put(PaymentRepository(api), permanent: true);
    Get.put(ComplaintRepository(api), permanent: true);
    Get.put(AnnouncementRepository(api), permanent: true);
    Get.put(NotificationRepository(api), permanent: true);
    Get.put(OrderRepository(api), permanent: true);
    Get.put(StockEntryRepository(api), permanent: true);
    Get.put(StockEntryDetailsRepository(api), permanent: true);
    Get.put(MaterialRequestRepository(api), permanent: true);
  }
}
