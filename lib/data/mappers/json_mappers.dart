import 'dart:convert';

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
import '../../domain/entities/stock_summary.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/user.dart';
import '../../utils/api_config.dart';
import '../../utils/html_plain_text.dart';

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
    final itemsRaw = json['items'];
    final items = <MaterialRequestItem>[];
    if (itemsRaw is List) {
      for (final row in itemsRaw) {
        if (row is! Map) continue;
        items.add(
          MaterialRequestItemMapper.fromJson(Map<String, dynamic>.from(row)),
        );
      }
    }
    return MaterialRequest(
      name: json['name']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      transactionDate: json['transaction_date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      materialRequestType: (json['material_request_type'] ??
                  json['purpose'] ??
                  json['type'] ??
                  '')
              .toString(),
      scheduleDate: json['schedule_date']?.toString() ?? '',
      warehouse: json['set_warehouse']?.toString() ??
          json['warehouse']?.toString() ??
          '',
      fromWarehouse: json['set_from_warehouse']?.toString() ??
          json['from_warehouse']?.toString() ??
          '',
      docstatus: int.tryParse('${json['docstatus'] ?? 0}') ?? 0,
      modified: (json['modified'] ??
              json['last_updated_on'] ??
              json['updated_on'] ??
              json['creation'] ??
              '')
          .toString(),
      items: items,
    );
  }
}

class MaterialRequestResponseMapper {
  static MaterialRequestResponse fromJson(Map<String, dynamic> json) {
    final root = json['message'] is Map
        ? Map<String, dynamic>.from(json['message'] as Map)
        : (json['message'] is List
            ? <String, dynamic>{'material_requests': json['message']}
            : json);

    final listRaw = _extractList(root) ?? _extractList(json);
    final entries = <MaterialRequest>[];
    if (listRaw != null) {
      for (final row in listRaw) {
        if (row is! Map) continue;
        try {
          final mr = MaterialRequestMapper.fromJson(
            Map<String, dynamic>.from(row),
          );
          if (mr.name.isEmpty) continue;
          entries.add(mr);
        } catch (_) {
          // Skip malformed rows so one bad doc doesn't empty the list.
        }
      }
    }

    final limit = int.tryParse('${root['limit'] ?? json['limit'] ?? 20}') ?? 20;
    final offset =
        int.tryParse('${root['offset'] ?? json['offset'] ?? 0}') ?? 0;
    final hasMoreFlag = root['has_more'] ?? json['has_more'];
    final hasMore = hasMoreFlag == true ||
        hasMoreFlag == 1 ||
        hasMoreFlag == '1' ||
        (hasMoreFlag == null && entries.length >= limit);

    entries.sort((a, b) {
      final da = a.modifiedAt;
      final db = b.modifiedAt;
      if (da == null && db == null) {
        return b.name.compareTo(a.name);
      }
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return MaterialRequestResponse(
      materialRequests: entries,
      isSearch: root['is_search'] == true || json['is_search'] == true,
      hasMore: hasMore,
      limit: limit,
      offset: offset,
    );
  }

  static List? _extractList(Map map) {
    for (final key in [
      'material_requests',
      'data',
      'requests',
      'docs',
      'message',
    ]) {
      final value = map[key];
      if (value is List) return value;
    }
    return null;
  }
}

class StockEntryMapper {
  static StockEntry fromJson(Map<String, dynamic> json) {
    dynamic rawName = json['name'] ??
        json['stock_entry_id'] ??
        json['stock_entry_name'] ??
        json['docname'] ??
        json['title'];
    if (rawName == null && json['stock_entry'] is String) {
      rawName = json['stock_entry'];
    }
    if (rawName == null && json['stock_entry'] is Map) {
      rawName = json['stock_entry']['name'];
    }
    final from = json['from'] ??
        json['from_warehouse'] ??
        json['s_warehouse'] ??
        json['source_warehouse'] ??
        json['source'] ??
        '';
    final to = json['to'] ??
        json['to_warehouse'] ??
        json['t_warehouse'] ??
        json['target_warehouse'] ??
        json['target'] ??
        '';
    return StockEntry(
      name: rawName?.toString() ?? '',
      postingDate: (json['posting_date'] ??
              json['postingDate'] ??
              json['date'] ??
              json['creation'] ??
              '')
          .toString(),
      from: from.toString(),
      to: to.toString(),
      status: (json['status'] ?? json['workflow_state'] ?? 'Pending').toString(),
    );
  }
}

class StockEntryResponseMapper {
  static StockEntryResponse fromJson(Map<String, dynamic> json) {
    final raw = _stockEntryRows(json);
    final entries = <StockEntry>[];
    for (final row in raw) {
      if (row is! Map) continue;
      final entry = StockEntryMapper.fromJson(Map<String, dynamic>.from(row));
      if (entry.name.isEmpty || entry.name == 'null') continue;
      entries.add(entry);
    }
    final msg = json['message'];
    final isSearch = msg is Map && msg['is_search'] == true;
    return StockEntryResponse(
      stockEntries: entries,
      isSearch: isSearch,
    );
  }

  static const _listKeys = [
    'stock_entries',
    'last_stock_entries',
    'stock_entry_list',
    'data',
    'entries',
    'docs',
    'result',
    'records',
    'values',
    'message',
  ];

  static List<dynamic> _stockEntryRows(dynamic json) {
    if (json is String) {
      final text = json.trim();
      if (text.startsWith('[') || text.startsWith('{')) {
        try {
          return _stockEntryRows(jsonDecode(text));
        } catch (_) {
          return const [];
        }
      }
      return const [];
    }
    if (json is List) {
      if (json.isNotEmpty && json.first is Map && _looksLikeEntryList(json)) {
        return json;
      }
      for (final item in json) {
        final nested = _stockEntryRows(item);
        if (nested.isNotEmpty) return nested;
      }
      return const [];
    }
    if (json is! Map) return const [];

    for (final key in _listKeys) {
      if (!json.containsKey(key)) continue;
      final nested = _stockEntryRows(json[key]);
      if (nested.isNotEmpty) return nested;
    }

    if (_looksLikeEntry(json)) {
      return [json];
    }
    return const [];
  }

  static bool _looksLikeEntryList(List list) {
    for (final item in list) {
      if (item is Map && _looksLikeEntry(item)) return true;
    }
    return false;
  }

  static bool _looksLikeEntry(Map map) {
    final name =
        (map['name'] ?? map['stock_entry_id'] ?? map['stock_entry_name'] ?? '')
            .toString()
            .toUpperCase();
    if (name.contains('STE')) return true;
    return map.containsKey('posting_date') ||
        map.containsKey('postingDate') ||
        map.containsKey('stock_entry_type') ||
        map.containsKey('from_warehouse') ||
        map.containsKey('s_warehouse');
  }
}

class StockEntryItemMapper {
  static StockEntryItem fromJson(Map<String, dynamic> json) => StockEntryItem(
        id: (json['id'] ?? json['name'] ?? '').toString(),
        idx: _asInt(json['idx']),
        itemCode: (json['itemCode'] ??
                json['item_code'] ??
                json['item'] ??
                '')
            .toString(),
        itemName: (json['itemName'] ?? json['item_name'] ?? '').toString(),
        fromWarehouse: (json['fromWarehouse'] ??
                json['from_warehouse'] ??
                json['s_warehouse'] ??
                '')
            .toString(),
        toWarehouse: (json['toWarehouse'] ??
                json['to_warehouse'] ??
                json['t_warehouse'] ??
                '')
            .toString(),
        quantity: _asInt(json['quantity'] ?? json['qty']),
      );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class StockEntryDetailsMapper {
  static StockEntryDetails fromJson(Map<String, dynamic> json) =>
      StockEntryDetails(
        name: (json['name'] ?? '').toString(),
        postingDate: (json['postingDate'] ??
                json['posting_date'] ??
                json['date'] ??
                '')
            .toString(),
        fromWarehouse: (json['fromWarehouse'] ??
                json['from_warehouse'] ??
                json['s_warehouse'] ??
                '')
            .toString(),
        toWarehouse: (json['toWarehouse'] ??
                json['to_warehouse'] ??
                json['t_warehouse'] ??
                '')
            .toString(),
        company: (json['company'] ?? '').toString(),
        status: (json['status'] ?? json['workflow_state'] ?? 'Pending')
            .toString(),
      );
}

class StockEntryDetailsResponseMapper {
  static StockEntryDetailsResponse fromJson(Map<String, dynamic> json) {
    final root = json['message'] is Map
        ? Map<String, dynamic>.from(json['message'] as Map)
        : json;

    Map<String, dynamic> header = {};
    for (final key in [
      'stockEntry',
      'stock_entry',
      'doc',
      'data',
    ]) {
      final value = root[key];
      if (value is Map) {
        header = Map<String, dynamic>.from(value);
        break;
      }
    }
    if (header.isEmpty && root.containsKey('name')) {
      header = root;
    }

    List itemsRaw = const [];
    for (final key in ['items', 'stock_entry_details', 'stock_items']) {
      final value = root[key] ?? header[key];
      if (value is List) {
        itemsRaw = value;
        break;
      }
    }

    return StockEntryDetailsResponse(
      stockEntry: StockEntryDetailsMapper.fromJson(header),
      items: itemsRaw
          .whereType<Map>()
          .map((i) => StockEntryItemMapper.fromJson(
                Map<String, dynamic>.from(i),
              ))
          .toList(),
    );
  }
}

class StockSummaryTotalsMapper {
  static StockSummaryTotals fromJson(Map<String, dynamic> json) =>
      StockSummaryTotals(
        totalItems: int.tryParse('${json['total_items'] ?? 0}') ?? 0,
        totalQty: jsonDouble(json['total_qty']),
        lowStockCount: int.tryParse('${json['low_stock_count'] ?? 0}') ?? 0,
      );
}

class StockSummaryItemMapper {
  static StockSummaryItem fromJson(Map<String, dynamic> json) =>
      StockSummaryItem(
        itemCode: json['item_code']?.toString() ?? '',
        itemName: json['item_name']?.toString() ?? '',
        warehouse: json['warehouse']?.toString() ?? '',
        qty: jsonDouble(json['qty']),
        uom: json['uom']?.toString() ?? 'Nos',
        isLowStock: json['is_low_stock'] == true ||
            json['is_low_stock'] == 1 ||
            json['is_low_stock'] == '1',
        reorderLevel: jsonDouble(json['reorder_level']),
      );
}

class StockSummaryResponseMapper {
  static StockSummaryResponse fromJson(Map<String, dynamic> json) {
    final root = json['message'] is Map
        ? Map<String, dynamic>.from(json['message'] as Map)
        : json;
    final summaryRaw = root['summary'];
    final summary = summaryRaw is Map
        ? StockSummaryTotalsMapper.fromJson(
            Map<String, dynamic>.from(summaryRaw),
          )
        : const StockSummaryTotals(
            totalItems: 0,
            totalQty: 0,
            lowStockCount: 0,
          );
    final itemsRaw = root['items'];
    final items = <StockSummaryItem>[];
    if (itemsRaw is List) {
      for (final row in itemsRaw) {
        if (row is! Map) continue;
        items.add(
          StockSummaryItemMapper.fromJson(Map<String, dynamic>.from(row)),
        );
      }
    }
    return StockSummaryResponse(
      warehouse: root['warehouse']?.toString() ?? '',
      company: root['company']?.toString() ?? '',
      summary: summary,
      items: items,
      isSearch: root['is_search'] == true,
      limit: int.tryParse('${root['limit'] ?? 20}') ?? 20,
      offset: int.tryParse('${root['offset'] ?? 0}') ?? 0,
      hasMore: root['has_more'] == true,
    );
  }
}

class TodoTaskMapper {
  static TodoTask fromJson(Map<String, dynamic> json) => TodoTask(
        name: json['name']?.toString() ?? '',
        description: stripHtmlToPlainText(json['description']?.toString()),
        status: json['status']?.toString() ?? 'Open',
        priority: json['priority']?.toString() ?? 'Medium',
        date: json['date']?.toString() ?? '',
        allocatedTo: json['allocated_to']?.toString() ?? '',
        assignedBy: json['assigned_by']?.toString() ?? '',
        referenceType: json['reference_type']?.toString() ?? '',
        referenceName: json['reference_name']?.toString() ?? '',
        creation: json['creation']?.toString() ?? '',
        modified: json['modified']?.toString() ?? '',
      );
}

class TaskSummaryMapper {
  static TaskSummary fromJson(Map<String, dynamic> json) => TaskSummary(
        totalItems: int.tryParse('${json['total_items'] ?? 0}') ?? 0,
        openCount: int.tryParse('${json['open_count'] ?? 0}') ?? 0,
        closedCount: int.tryParse('${json['closed_count'] ?? 0}') ?? 0,
        overdueCount: int.tryParse('${json['overdue_count'] ?? 0}') ?? 0,
      );
}

class TaskListResponseMapper {
  static TaskListResponse fromJson(Map<String, dynamic> json) {
    final root = json['message'] is Map
        ? Map<String, dynamic>.from(json['message'] as Map)
        : json;
    final summaryRaw = root['summary'];
    final summary = summaryRaw is Map
        ? TaskSummaryMapper.fromJson(Map<String, dynamic>.from(summaryRaw))
        : const TaskSummary(
            totalItems: 0,
            openCount: 0,
            closedCount: 0,
            overdueCount: 0,
          );
    final tasksRaw = root['tasks'];
    final tasks = <TodoTask>[];
    if (tasksRaw is List) {
      for (final row in tasksRaw) {
        if (row is! Map) continue;
        tasks.add(TodoTaskMapper.fromJson(Map<String, dynamic>.from(row)));
      }
    }
    return TaskListResponse(
      user: root['user']?.toString() ?? '',
      date: root['date']?.toString() ?? '',
      status: root['status']?.toString() ?? 'Open',
      summary: summary,
      tasks: tasks,
      isSearch: root['is_search'] == true,
      limit: int.tryParse('${root['limit'] ?? 20}') ?? 20,
      offset: int.tryParse('${root['offset'] ?? 0}') ?? 0,
      hasMore: root['has_more'] == true,
    );
  }
}
