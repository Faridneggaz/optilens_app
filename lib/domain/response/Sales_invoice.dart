class SalesInvoice {
  final String name;
  final String posting_date;
  final double grand_total;
  final double outstanding_amount;
  final String status;
  final int is_pos;
  SalesInvoice({
    required this.name,
    required this.posting_date,
    required this.grand_total,
    required this.is_pos,
    required this.outstanding_amount,
    required this.status,
  });
  static SalesInvoice fromJson(Map<String, dynamic> json) {
    return SalesInvoice(
      name: json["name"],
      posting_date: json["posting_date"],
      grand_total: json["grand_total"],
      outstanding_amount: json["outstanding_amount"],
      status: json["status"],
      is_pos: json["is_pos"],
    );
  }
}
