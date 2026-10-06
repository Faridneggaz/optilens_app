import '../entities/manque.dart';
import '../repositories/manque_repository.dart';
import '../results/action_result.dart';

class ManqueUseCases {
  ManqueUseCases(this._repo);
  final ManqueRepository _repo;

  Future<List<BuyerOption>> fetchBuyers({required String token}) =>
      _repo.fetchBuyers(token: token);

  Future<List<CustomerOption>> fetchCustomers({
    required String token,
    required String company,
    String? searchText,
  }) =>
      _repo.fetchCustomers(
        token: token,
        company: company,
        searchText: searchText,
      );

  Future<List<SupplierOption>> fetchSuppliers({
    required String token,
    String? company,
    String? searchText,
  }) =>
      _repo.fetchSuppliers(
        token: token,
        company: company,
        searchText: searchText,
      );

  Future<CommandeManqueListResponse> fetchCommandes({
    required String token,
    int limit = 50,
    int offset = 0,
    String? searchText,
    String status = 'All',
  }) =>
      _repo.fetchCommandes(
        token: token,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );

  Future<CommandeDeManque> fetchCommandeDetail({
    required String token,
    required String name,
  }) =>
      _repo.fetchCommandeDetail(token: token, name: name);

  Future<ActionResult> createCommande({
    required String token,
    required String company,
    required String warehouse,
    required String buyer,
    required String customer,
    String customerName = '',
    String? transactionDate,
    required List<Map<String, dynamic>> items,
    required bool envoyer,
  }) =>
      _repo.createCommande(
        token: token,
        company: company,
        warehouse: warehouse,
        buyer: buyer,
        customer: customer,
        customerName: customerName,
        transactionDate: transactionDate,
        items: items,
        envoyer: envoyer,
      );

  Future<ActionResult> manageCommande({
    required String token,
    required String name,
    required String action,
  }) =>
      _repo.manageCommande(token: token, name: name, action: action);

  Future<FactureAcheteurListResponse> fetchFactures({
    required String token,
    int limit = 50,
    int offset = 0,
    String? searchText,
    String? status,
  }) =>
      _repo.fetchFactures(
        token: token,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );

  Future<FactureAcheteur> fetchFactureDetail({
    required String token,
    required String name,
  }) =>
      _repo.fetchFactureDetail(token: token, name: name);

  Future<ActionResult> createFacture({
    required String token,
    required String commandeDeManque,
  }) =>
      _repo.createFacture(token: token, commandeDeManque: commandeDeManque);

  Future<ActionResult> saveFactureDraft({
    required String token,
    required String name,
    required String modeAchat,
    required String supplier,
    required List<Map<String, dynamic>> items,
  }) =>
      _repo.saveFactureDraft(
        token: token,
        name: name,
        modeAchat: modeAchat,
        supplier: supplier,
        items: items,
      );

  Future<ActionResult> submitFacture({
    required String token,
    required String name,
    required String modeAchat,
    required String supplier,
    required List<Map<String, dynamic>> items,
  }) =>
      _repo.submitFacture(
        token: token,
        name: name,
        modeAchat: modeAchat,
        supplier: supplier,
        items: items,
      );

  Future<ActionResult> payFacture({
    required String token,
    required String name,
  }) =>
      _repo.payFacture(token: token, name: name);

  Future<ActionResult> cancelFacture({
    required String token,
    required String name,
  }) =>
      _repo.cancelFacture(token: token, name: name);
}
