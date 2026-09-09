import '../../domain/entities/announcement.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_response.dart';
import '../../domain/entities/invoice_detail_response.dart';
import '../../domain/entities/invoices_response.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/entities/material_request_response.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_invoice.dart';
import '../../domain/entities/payment_response.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/stock_entry.dart';
import '../../domain/entities/stock_entry_details.dart';
import '../../domain/entities/stock_entry_details_response.dart';
import '../../domain/entities/stock_entry_item.dart';
import '../../domain/entities/stock_entry_response.dart';
import '../../domain/entities/user.dart';
import '../../utils/api_config.dart';

double jsonDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class ItemMapper {
  static Item fromJson(Map<String, dynamic> json) => Item(
        itemCode: json['item_code']?.toString() ?? '',
        itemName: json['item_name']?.toString() ?? '',
        rate: double.tryParse(
              (json['standard_rate'] ?? json['rate'] ?? 0.0).toString(),
            ) ??
            0.0,
        currency: json['currency']?.toString() ?? 'DZD',
        uom: json['uom']?.toString() ?? 'Nos',
      );
}

class UserMapper {
  static User fromJson(Map<String, dynamic> json) => User(
        sid: json['sid']?.toString() ?? '',
        email: json['email']?.toString(),
        name: json['name']?.toString(),
        allowedCompanies: (json['allowed_companies'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        allowedWarehouses: (json['allowed_warehouses'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

class LoginResponseMapper {
  static LoginResponse fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    if (message is! Map<String, dynamic>) {
      throw Exception('Login failed - Invalid response format');
    }
    final userData = message['user'];
    if (userData is! Map<String, dynamic>) {
      throw Exception('Login failed - Invalid user data format');
    }
    return LoginResponse(user: UserMapper.fromJson(userData));
  }
}

class CustomerMapper {
  static Customer fromJson(Map<String, dynamic> json) => Customer(
        name: json['name'],
        code: json['custom_customer_code'],
        debt: json['custom_debt'],
        email: json['email_id'],
        mobile: json['mobile_no'],
        priceList: json['default_price_list'] ?? 'Standard',
      );
}

class CustomerResponseMapper {
  static CustomerResponse fromJson(Map<String, dynamic> json) {
    final customerJson = json['message']['customer'];
    if (customerJson == null) {
      throw Exception('Customer data not found');
    }
    return CustomerResponse(
      customer: CustomerMapper.fromJson(
        Map<String, dynamic>.from(customerJson as Map),
      ),
    );
  }
}

class SalesInvoiceMapper {
  static SalesInvoice fromJson(Map<String, dynamic> json) => SalesInvoice(
        name: json['name'],
        postingDate: json['posting_date'],
        grandTotal: (json['grand_total'] as num).toDouble(),
        outstandingAmount: (json['outstanding_amount'] as num).toDouble(),
        status: json['status'],
        isPos: json['is_pos'],
      );
}

class InvoicesResponseMapper {
  static InvoicesResponse fromJson(Map<String, dynamic> json) =>
      InvoicesResponse(
        customerCode: json['message']['customer_code'],
        salesInvoices: (json['message']['sales_invoices'] as List)
            .map((s) => SalesInvoiceMapper.fromJson(
                  Map<String, dynamic>.from(s as Map),
                ))
            .toList(),
        posInvoices: (json['message']['pos_invoices'] as List)
            .map((p) => SalesInvoiceMapper.fromJson(
                  Map<String, dynamic>.from(p as Map),
                ))
            .toList(),
        isSearch: json['message']['is_search'] ?? false,
      );
}

class PaymentInvoiceMapper {
  static PaymentInvoice fromJson(Map<String, dynamic> json) => PaymentInvoice(
        invoice: json['invoice'] ?? '',
        allocatedAmount: (json['allocated_amount'] as num?)?.toDouble() ?? 0.0,
        invoicePostingDate: json['invoice_posting_date'] ?? '',
        invoiceStatus: json['invoice_status'] ?? '',
        invoiceTotal: (json['invoice_total'] as num?)?.toDouble() ?? 0.0,
        invoiceOutstanding:
            (json['invoice_outstanding'] as num?)?.toDouble() ?? 0.0,
      );
}

class PaymentMapper {
  static Payment fromJson(Map<String, dynamic> json) => Payment(
        name: json['name'] ?? '',
        postingDate: json['posting_date'] ?? '',
        paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
        paymentType: json['payment_type'] ?? '',
        modeOfPayment: json['mode_of_payment'],
        invoicesPayed: json['invoices_payed'] != null
            ? (json['invoices_payed'] as List)
                .map((i) => PaymentInvoiceMapper.fromJson(
                      Map<String, dynamic>.from(i as Map),
                    ))
                .toList()
            : const [],
      );
}

class PaymentResponseMapper {
  static PaymentResponse fromJson(Map<String, dynamic> json, int limit) {
    final message = json['message'];
    List<Payment> list = [];
    var isSearch = false;

    if (message is List) {
      list = message
          .map((p) => PaymentMapper.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
    } else if (message is Map && message.containsKey('payments')) {
      list = (message['payments'] as List)
          .map((p) => PaymentMapper.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      isSearch = message['is_search'] ?? false;
    }

    return PaymentResponse(
      payments: list,
      hasMore: list.length >= limit,
      isSearch: isSearch,
    );
  }
}

class InvoiceDetailMapper {
  static InvoiceDetail fromJson(Map<String, dynamic> json) => InvoiceDetail(
        name: json['name'] ?? '',
        postingDate: json['posting_date'] ?? '',
        grandTotal: jsonDouble(json['grand_total']),
        outstandingAmount: jsonDouble(json['outstanding_amount']),
        status: json['status'] ?? '',
        totalQty: jsonDouble(json['total_qty']),
        customer: json['customer'],
      );
}

class InvoiceItemMapper {
  static InvoiceItem fromJson(Map<String, dynamic> json) => InvoiceItem(
        itemCode: json['item_code'] ?? '',
        itemName: json['item_name'] ?? json['item_code'] ?? '',
        qty: jsonDouble(json['qty']),
        rate: jsonDouble(json['rate']),
        amount: jsonDouble(json['amount']),
      );
}

class InvoiceDetailResponseMapper {
  static InvoiceDetailResponse fromJson(Map<String, dynamic> json) =>
      InvoiceDetailResponse(
        invoice: InvoiceDetailMapper.fromJson(
          Map<String, dynamic>.from((json['invoice'] ?? {}) as Map),
        ),
        items: (json['items'] as List<dynamic>?)
                ?.map((item) => InvoiceItemMapper.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ))
                .toList() ??
            const [],
      );
}

class AnnouncementMapper {
  static Announcement fromJson(Map<String, dynamic> json) {
    final rawImage = json['image'] ?? json['banner_image'];
    String? fullImageUrl;
    if (rawImage != null && rawImage.toString().isNotEmpty) {
      final raw = rawImage.toString();
      fullImageUrl =
          raw.startsWith('http') ? raw : '${ApiConfig.baseUrl}$raw';
    }
    return Announcement(
      id: json['id'] ?? json['name'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? json['description'] ?? '',
      type: json['type'] ?? json['announcement_typ'] ?? 'Info',
      priority: json['priority'] ?? 'Medium',
      color: json['color'] ?? '#00A89C',
      postedTime: json['postedTime'] ?? json['publish_date'] ?? '',
      image: fullImageUrl,
    );
  }
}

class MaterialRequestItemMapper {
  static MaterialRequestItem fromJson(Map<String, dynamic> json) =>
      MaterialRequestItem(
        itemCode: json['item_code']?.toString() ?? '',
        itemName: json['item_name']?.toString() ?? '',
        qty: double.tryParse(json['qty']?.toString() ?? '0') ?? 0,
        receivedQty:
            double.tryParse(json['received_qty']?.toString() ?? '0') ?? 0,
        uom: json['uom']?.toString() ?? '',
        warehouse: json['warehouse']?.toString() ?? '',
        scheduleDate: json['schedule_date']?.toString() ?? '',
      );
}

class MaterialRequestMapper {
  static MaterialRequest fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List?;
    return MaterialRequest(
      name: json['name']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      transactionDate: json['transaction_date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      materialRequestType: json['material_request_type']?.toString() ?? '',
      scheduleDate: json['schedule_date']?.toString() ?? '',
      warehouse: json['set_warehouse']?.toString() ??
          json['warehouse']?.toString() ??
          '',
      fromWarehouse: json['set_from_warehouse']?.toString() ??
          json['from_warehouse']?.toString() ??
          '',
      docstatus: json['docstatus'] ?? 0,
      items: itemsList != null
          ? itemsList
              .map((i) => MaterialRequestItemMapper.fromJson(
                    Map<String, dynamic>.from(i as Map),
                  ))
              .toList()
          : const [],
    );
  }
}

class MaterialRequestResponseMapper {
  static MaterialRequestResponse fromJson(Map<String, dynamic> json) {
    final msg = json['message'] ?? json;
    List<MaterialRequest> entries = [];
    var isSearch = false;

    if (msg is List) {
      entries = msg
          .map((e) => MaterialRequestMapper.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } else if (msg is Map && msg.containsKey('material_requests')) {
      entries = (msg['material_requests'] as List)
          .map((e) => MaterialRequestMapper.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
      isSearch = msg['is_search'] ?? false;
    }

    return MaterialRequestResponse(
      materialRequests: entries,
      isSearch: isSearch,
    );
  }
}

class StockEntryMapper {
  static StockEntry fromJson(Map<String, dynamic> json) => StockEntry(
        name: json['name'],
        postingDate: json['posting_date'],
        from: json['from'] ?? '',
        to: json['to'] ?? '',
        status: json['status'],
      );
}

class StockEntryResponseMapper {
  static StockEntryResponse fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    List<StockEntry> entries = [];
    var isSearch = false;

    if (message is List) {
      entries = message
          .map((e) =>
              StockEntryMapper.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (message is Map && message.containsKey('stock_entries')) {
      entries = (message['stock_entries'] as List)
          .map((e) =>
              StockEntryMapper.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      isSearch = message['is_search'] ?? false;
    }

    return StockEntryResponse(
      stockEntries: entries,
      isSearch: isSearch,
    );
  }
}

class StockEntryItemMapper {
  static StockEntryItem fromJson(Map<String, dynamic> json) => StockEntryItem(
        id: json['id'] ?? '',
        idx: json['idx'] ?? 0,
        itemCode: json['itemCode'] ?? '',
        itemName: json['itemName'] ?? '',
        fromWarehouse: json['fromWarehouse'] ?? '',
        toWarehouse: json['toWarehouse'] ?? '',
        quantity: (json['quantity'] ?? 0).toInt(),
      );
}

class StockEntryDetailsMapper {
  static StockEntryDetails fromJson(Map<String, dynamic> json) =>
      StockEntryDetails(
        name: json['name'],
        postingDate: json['postingDate'],
        fromWarehouse: json['fromWarehouse'] ?? '',
        toWarehouse: json['toWarehouse'] ?? '',
        company: json['company'],
        status: json['status'],
      );
}

class StockEntryDetailsResponseMapper {
  static StockEntryDetailsResponse fromJson(Map<String, dynamic> json) =>
      StockEntryDetailsResponse(
        stockEntry: StockEntryDetailsMapper.fromJson(
          Map<String, dynamic>.from(json['message']['stockEntry'] as Map),
        ),
        items: (json['message']['items'] as List)
            .map((i) => StockEntryItemMapper.fromJson(
                  Map<String, dynamic>.from(i as Map),
                ))
            .toList(),
      );
}
