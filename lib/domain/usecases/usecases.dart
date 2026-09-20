import '../entities/announcement.dart';
import '../entities/customer_response.dart';
import '../entities/invoice_detail_response.dart';
import '../entities/invoices_response.dart';
import '../entities/item.dart';
import '../entities/login_response.dart';
import '../entities/material_request_response.dart';
import '../entities/payment_response.dart';
import '../entities/stock_entry_details_response.dart';
import '../entities/stock_entry_response.dart';
import '../entities/stock_summary.dart';
import '../entities/task.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/complaint_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_detail_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/joptic_complaint_repository.dart';
import '../repositories/lead_repository.dart';
import '../repositories/login_repository.dart';
import '../repositories/material_request_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/stock_entry_details_repository.dart';
import '../repositories/stock_entry_repository.dart';
import '../repositories/task_repository.dart';
import '../results/action_result.dart';

class AuthUseCases {
  AuthUseCases(this._login, this._customers);
  final LoginRepository _login;
  final CustomerRepository _customers;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final result = await _login.login(email: email, password: password);
    if (result.user.sid.isEmpty) {
      throw const MissingTokenException();
    }
    return result;
  }

  Future<CustomerResponse> fetchCustomer(String code) =>
      _customers.fetchCustomer(code);

  Future<ChangeCodeResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final map = await _customers.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    return ChangeCodeResult(
      success: map['success'] == true,
      error: map['error']?.toString(),
    );
  }
}

class InvoiceUseCases {
  InvoiceUseCases(this._invoices, this._details);
  final InvoiceRepository _invoices;
  final InvoiceDetailRepository _details;

  Future<InvoicesResponse> fetchInvoices(
    String customerCode, {
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) =>
      _invoices.fetchInvoices(
        customerCode,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );

  Future<InvoiceDetailResponse> getInvoiceDetails(String invoiceName) =>
      _details.getInvoiceDetails(invoiceName: invoiceName);
}

class PaymentUseCases {
  PaymentUseCases(this._repo);
  final PaymentRepository _repo;

  Future<PaymentResponse> fetchPayments(
    String customerCode, {
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) =>
      _repo.fetchPayments(
        customerCode,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );
}

class AnnouncementUseCases {
  AnnouncementUseCases(this._repo);
  final AnnouncementRepository _repo;

  Future<List<Announcement>> fetchAnnouncements(
    String customerCode, {
    int limit = 10,
    int offset = 0,
  }) =>
      _repo.fetchAnnouncements(customerCode, limit: limit, offset: offset);
}

class NotificationUseCases {
  NotificationUseCases(this._repo);
  final NotificationRepository _repo;

  Future<List<dynamic>> fetchNotifications(String customerCode) =>
      _repo.fetchNotifications(customerCode);
}

class ComplaintUseCases {
  ComplaintUseCases(this._repo);
  final ComplaintRepository _repo;

  Future<void> submitComplaint({
    required String client,
    required String description,
  }) =>
      _repo.submitComplaint(client: client, description: description);
}

class OrderUseCases {
  OrderUseCases(this._repo);
  final OrderRepository _repo;

  Future<List<Item>> fetchItems(String customerCode) =>
      _repo.fetchItems(customerCode);

  Future<List<Item>> searchItems({
    required String searchText,
    required String customerCode,
  }) =>
      _repo.searchItems(searchText: searchText, customerCode: customerCode);

  Future<bool> submitOrder({
    required String customerCode,
    required List<Map<String, dynamic>> items,
  }) =>
      _repo.submitOrder(customerCode: customerCode, items: items);

  Future<List<dynamic>> fetchOrders(String customerCode) =>
      _repo.fetchOrders(customerCode);

  Future<List<dynamic>?> getOrderItems(String orderId) =>
      _repo.getOrderItems(orderId);
}

class StockEntryUseCases {
  StockEntryUseCases(this._list, this._details);
  final StockEntryRepository _list;
  final StockEntryDetailsRepository _details;

  Future<StockEntryResponse> fetchLastStockEntries({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) =>
      _list.fetchLastStockEntries(
        token: token,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );

  Future<StockSummaryResponse> fetchStockSummary({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? warehouse,
    String? company,
    bool onlyInStock = true,
    bool onlyNegative = false,
    bool includeLowStockOnly = false,
  }) =>
      _list.fetchStockSummary(
        token: token,
        limit: limit,
        offset: offset,
        searchText: searchText,
        warehouse: warehouse,
        company: company,
        onlyInStock: onlyInStock,
        onlyNegative: onlyNegative,
        includeLowStockOnly: includeLowStockOnly,
      );

  Future<StockEntryDetailsResponse> fetchDetails({
    required String name,
    required String token,
  }) =>
      _details.fetchDetails(name: name, token: token);

  Future<ActionResult> approveStockEntry({
    required String name,
    required String token,
    required List<Map<String, dynamic>> items,
    required String action,
  }) async {
    try {
      final map = await _details.approveStockEntry(
        name: name,
        token: token,
        items: items,
        action: action,
      );
      return ActionResult.fromApiMap(map);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  }) =>
      _details.searchItems(token: token, searchText: searchText);
}

class MaterialRequestUseCases {
  MaterialRequestUseCases(this._repo);
  final MaterialRequestRepository _repo;

  Future<MaterialRequestResponse> fetchMaterialRequests({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) =>
      _repo.fetchMaterialRequests(
        token: token,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );

  Future<MaterialRequest> fetchDetail({
    required String token,
    required String name,
  }) =>
      _repo.fetchDetail(token: token, name: name);

  Future<List<Map<String, String>>> fetchWarehouses({
    required String token,
    required String company,
  }) =>
      _repo.fetchWarehouses(token: token, company: company);

  Future<List<String>> fetchCompanies({required String token}) =>
      _repo.fetchCompanies(token: token);

  Future<List<String>> fetchPriceLists({required String token}) =>
      _repo.fetchPriceLists(token: token);

  Future<ActionResult> createMaterialRequest({
    required String token,
    required String company,
    required String purpose,
    required String requiredBy,
    required String setWarehouse,
    String? setFromWarehouse,
    String? priceList,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final map = await _repo.createMaterialRequest(
        token: token,
        company: company,
        purpose: purpose,
        requiredBy: requiredBy,
        setWarehouse: setWarehouse,
        setFromWarehouse: setFromWarehouse,
        priceList: priceList,
        items: items,
      );
      return ActionResult.fromApiMap(map);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  Future<ActionResult> manageMaterialRequest({
    required String token,
    required String name,
    required String action,
  }) async {
    try {
      final map = await _repo.manageMaterialRequest(
        token: token,
        name: name,
        action: action,
      );
      return ActionResult.fromApiMap(map);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  Future<ActionResult> createStockEntryFromMR({
    required String token,
    required String name,
    String? purpose,
  }) async {
    try {
      final map = await _repo.createStockEntryFromMR(
        token: token,
        name: name,
        purpose: purpose,
      );
      return ActionResult.fromApiMap(map);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  }) =>
      _repo.searchItems(token: token, searchText: searchText);
}

class JopticUseCases {
  JopticUseCases(this._leads, this._complaints);
  final LeadRepository _leads;
  final JopticComplaintRepository _complaints;

  Future<void> createLead({required String name, required String phone}) =>
      _leads.createLead(name: name, phone: phone);

  Future<void> submitComplaint({
    required String clientName,
    required String description,
  }) =>
      _complaints.submitComplaint(
        clientName: clientName,
        description: description,
      );
}

class TaskUseCases {
  TaskUseCases(this._repo);
  final TaskRepository _repo;

  Future<TaskListResponse> fetchMyTasks({
    required String token,
    String status = 'Open',
    String? date,
    bool includeOverdue = true,
    String? searchText,
    int limit = 20,
    int offset = 0,
  }) =>
      _repo.fetchMyTasks(
        token: token,
        status: status,
        date: date,
        includeOverdue: includeOverdue,
        searchText: searchText,
        limit: limit,
        offset: offset,
      );

  Future<TodoTask> fetchTaskDetail({
    required String token,
    required String name,
  }) =>
      _repo.fetchTaskDetail(token: token, name: name);

  Future<ActionResult> updateTaskStatus({
    required String token,
    required String name,
    required String status,
  }) =>
      _repo.updateTaskStatus(token: token, name: name, status: status);
}
