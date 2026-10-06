import '../entities/manque.dart';
import '../results/action_result.dart';

abstract class ManqueRepository {
  Future<List<BuyerOption>> fetchBuyers({required String token});

  Future<List<CustomerOption>> fetchCustomers({
    required String token,
    required String company,
    String? searchText,
  });

  Future<List<SupplierOption>> fetchSuppliers({
    required String token,
    String? company,
    String? searchText,
  });

  Future<CommandeManqueListResponse> fetchCommandes({
    required String token,
    int limit = 50,
    int offset = 0,
    String? searchText,
    String status = 'All',
  });

  Future<CommandeDeManque> fetchCommandeDetail({
    required String token,
    required String name,
  });

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
  });

  Future<ActionResult> manageCommande({
    required String token,
    required String name,
    required String action,
  });

  Future<FactureAcheteurListResponse> fetchFactures({
    required String token,
    int limit = 50,
    int offset = 0,
    String? searchText,
    String? status,
  });

  Future<FactureAcheteur> fetchFactureDetail({
    required String token,
    required String name,
  });

  Future<ActionResult> createFacture({
    required String token,
    required String commandeDeManque,
  });

  Future<ActionResult> saveFactureDraft({
    required String token,
    required String name,
    required String modeAchat,
    required String supplier,
    required List<Map<String, dynamic>> items,
  });

  Future<ActionResult> submitFacture({
    required String token,
    required String name,
    required String modeAchat,
    required String supplier,
    required List<Map<String, dynamic>> items,
  });

  Future<ActionResult> payFacture({
    required String token,
    required String name,
  });

  Future<ActionResult> cancelFacture({
    required String token,
    required String name,
  });
}
