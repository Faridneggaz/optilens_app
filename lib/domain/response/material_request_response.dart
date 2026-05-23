class MaterialRequestItem {
  final String itemCode;
  final String itemName;
  final double qty;
  final double receivedQty;
  final String uom;
  final String warehouse;
  final String scheduleDate;

  MaterialRequestItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.receivedQty,
    required this.uom,
    required this.warehouse,
    required this.scheduleDate,
  });

  factory MaterialRequestItem.fromJson(Map<String, dynamic> json) {
    return MaterialRequestItem(
      itemCode:     json['item_code']?.toString() ?? '',
      itemName:     json['item_name']?.toString() ?? '',
      qty:          double.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      receivedQty:  double.tryParse(json['received_qty']?.toString() ?? '0') ?? 0,
      uom:          json['uom']?.toString() ?? '',
      warehouse:    json['warehouse']?.toString() ?? '',
      scheduleDate: json['schedule_date']?.toString() ?? '',
    );
  }
}

class MaterialRequest {
  final String name;
  final String company;
  final String transactionDate;
  final String status;
  final String materialRequestType;
  final String scheduleDate;
  final String warehouse;
  final String fromWarehouse;
  final int docstatus;
  final List<MaterialRequestItem> items;

  MaterialRequest({
    required this.name,
    required this.company,
    required this.transactionDate,
    required this.status,
    required this.materialRequestType,
    required this.scheduleDate,
    required this.warehouse,
    required this.fromWarehouse,
    required this.docstatus,
    required this.items,
  });

  factory MaterialRequest.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List?;
    return MaterialRequest(
      name:                json['name']?.toString() ?? '',
      company:             json['company']?.toString() ?? '',
      transactionDate:     json['transaction_date']?.toString() ?? '',
      status:              json['status']?.toString() ?? '',
      materialRequestType: json['material_request_type']?.toString() ?? '',
      scheduleDate:        json['schedule_date']?.toString() ?? '',
      warehouse:           json['set_warehouse']?.toString() ?? json['warehouse']?.toString() ?? '',
      fromWarehouse:       json['set_from_warehouse']?.toString() ?? json['from_warehouse']?.toString() ?? '',
      docstatus:           json['docstatus'] ?? 0,
      items: itemsList != null
          ? itemsList.map((i) => MaterialRequestItem.fromJson(i)).toList()
          : [],
    );
  }
}

class MaterialRequestResponse {
  final List<MaterialRequest> materialRequests;
  final bool isSearch;

  MaterialRequestResponse({
    required this.materialRequests,
    this.isSearch = false,
  });

  factory MaterialRequestResponse.fromJson(Map<String, dynamic> json) {
    final msg = json['message'] ?? json;
    List<MaterialRequest> entries = [];
    bool isSearch = false;

    if (msg is List) {
      entries = msg.map((e) => MaterialRequest.fromJson(e)).toList();
    } else if (msg is Map && msg.containsKey('material_requests')) {
      entries = (msg['material_requests'] as List)
          .map((e) => MaterialRequest.fromJson(e))
          .toList();
      isSearch = msg['is_search'] ?? false;
    }

    return MaterialRequestResponse(
      materialRequests: entries,
      isSearch:         isSearch,
    );
  }
}
