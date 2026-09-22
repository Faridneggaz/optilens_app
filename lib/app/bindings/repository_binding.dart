import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../data/repositories/complaint_joptic_repository.dart';
import '../../data/repositories/complaint_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_detail_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/lead_repository.dart';
import '../../data/repositories/login_repository.dart';
import '../../data/repositories/material_request_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/stock_entry_details_repository.dart';
import '../../data/repositories/stock_entry_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/job_profile_repository.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/repositories/complaint_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/invoice_detail_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/joptic_complaint_repository.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../domain/repositories/login_repository.dart';
import '../../domain/repositories/material_request_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/stock_entry_details_repository.dart';
import '../../domain/repositories/stock_entry_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/job_profile_repository.dart';
import '../../domain/usecases/usecases.dart';

/// Registers data implementations and domain use cases.
class RepositoryBinding {
  static void register() {
    final api = Get.find<ApiClient>();

    Get.put<CustomerRepository>(CustomerRepositoryImpl(api), permanent: true);
    Get.put<LoginRepository>(LoginRepositoryImpl(api), permanent: true);
    Get.put<InvoiceRepository>(InvoiceRepositoryImpl(api), permanent: true);
    Get.put<InvoiceDetailRepository>(
      InvoiceDetailRepositoryImpl(api),
      permanent: true,
    );
    Get.put<PaymentRepository>(PaymentRepositoryImpl(api), permanent: true);
    Get.put<ComplaintRepository>(ComplaintRepositoryImpl(api), permanent: true);
    Get.put<AnnouncementRepository>(
      AnnouncementRepositoryImpl(api),
      permanent: true,
    );
    Get.put<NotificationRepository>(
      NotificationRepositoryImpl(api),
      permanent: true,
    );
    Get.put<OrderRepository>(OrderRepositoryImpl(api), permanent: true);
    Get.put<StockEntryRepository>(
      StockEntryRepositoryImpl(api),
      permanent: true,
    );
    Get.put<StockEntryDetailsRepository>(
      StockEntryDetailsRepositoryImpl(api),
      permanent: true,
    );
    Get.put<MaterialRequestRepository>(
      MaterialRequestRepositoryImpl(api),
      permanent: true,
    );
    Get.put<TaskRepository>(TaskRepositoryImpl(api), permanent: true);
    Get.put<JobProfileRepository>(
      JobProfileRepositoryImpl(api),
      permanent: true,
    );
    Get.put<LeadRepository>(LeadRepositoryImpl(api), permanent: true);
    Get.put<JopticComplaintRepository>(
      JopticComplaintRepositoryImpl(api),
      permanent: true,
    );

    Get.put(
      AuthUseCases(Get.find(), Get.find()),
      permanent: true,
    );
    Get.put(
      InvoiceUseCases(Get.find(), Get.find()),
      permanent: true,
    );
    Get.put(PaymentUseCases(Get.find()), permanent: true);
    Get.put(AnnouncementUseCases(Get.find()), permanent: true);
    Get.put(NotificationUseCases(Get.find()), permanent: true);
    Get.put(ComplaintUseCases(Get.find()), permanent: true);
    Get.put(OrderUseCases(Get.find()), permanent: true);
    Get.put(
      StockEntryUseCases(Get.find(), Get.find()),
      permanent: true,
    );
    Get.put(MaterialRequestUseCases(Get.find()), permanent: true);
    Get.put(TaskUseCases(Get.find()), permanent: true);
    Get.put(JobProfileUseCases(Get.find()), permanent: true);
    Get.put(JopticUseCases(Get.find(), Get.find()), permanent: true);
  }
}
