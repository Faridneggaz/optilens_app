class CustomerComplaint {
  final String name; 
  final String client;
  final String dateReception;
  final String description;

  CustomerComplaint({
    required this.name,
    required this.client,
    required this.dateReception,
    required this.description,
  });

  factory CustomerComplaint.fromJson(Map<String, dynamic> json) {
    return CustomerComplaint(
      name: json['name'] ?? "",
      client: json['client'] ?? "",
      dateReception: json['date_reception'] ?? "",
      description: json['desciption_reclamation'] ?? "",
    );
  }
}