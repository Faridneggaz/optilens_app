class StockEntry {
  final String name;
  final String postingDate;
  final String from;
  final String to;
  final String status;

  StockEntry({
    required this.name,
    required this.postingDate,
    required this.from,
    required this.to,
    required this.status,
  });

  static StockEntry fromJson(Map<String, dynamic> json) {
    return StockEntry(
      name: json["name"],
      postingDate: json["posting_date"],
      from: json["from"] ?? "",
      to: json["to"] ?? "",
      status: json["status"],
    );
  }
}
