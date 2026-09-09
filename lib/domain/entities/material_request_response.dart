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
}

class MaterialRequestResponse {
  final List<MaterialRequest> materialRequests;
  final bool isSearch;

  MaterialRequestResponse({
    required this.materialRequests,
    this.isSearch = false,
  });
}
