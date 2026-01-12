class StockEntryDetails {
  final String name;
  final String posting_date;
  final String from_warehouse;
  final String to_warehouse;
  final String company;
  final String status;

  StockEntryDetails({
    required this.name,
    required this.posting_date,
    required this.from_warehouse,
    required this.to_warehouse,
    required this.company,
    required this.status,
  });

  static StockEntryDetails fromJson(Map<String, dynamic> json) {
    return StockEntryDetails(
      name: json["name"],
      posting_date: json["postingDate"],
      from_warehouse: json["fromWarehouse"] ?? "",
      to_warehouse: json["toWarehouse"] ?? "",
      company: json["company"],
      status: json["status"],
    );
  }
}
