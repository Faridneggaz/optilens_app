class StockEntryDetails {
  final String name;
  final String postingDate;
  final String fromWarehouse;
  final String toWarehouse;
  final String company;
  String status;

  StockEntryDetails({
    required this.name,
    required this.postingDate,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.company,
    required this.status,
  });

  static StockEntryDetails fromJson(Map<String, dynamic> json) {
    return StockEntryDetails(
      name: json["name"],
      postingDate: json["postingDate"],
      fromWarehouse: json["fromWarehouse"] ?? "",
      toWarehouse: json["toWarehouse"] ?? "",
      company: json["company"],
      status: json["status"],
    );
  }
}
