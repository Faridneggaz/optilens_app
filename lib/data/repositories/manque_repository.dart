import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../domain/entities/manque.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/manque_repository.dart';
import '../../domain/results/action_result.dart';
import '../../utils/api_config.dart';
import '../mappers/manque_mappers.dart';

class ManqueRepositoryImpl implements ManqueRepository {
  ManqueRepositoryImpl(this._client);

  final ApiClient _client;

  Map<String, dynamic> _asMap(dynamic msg) {
    if (msg is Map) return Map<String, dynamic>.from(msg);
    throw const RepositoryException('Invalid response format');
  }

  ActionResult _actionFrom(dynamic msg) {
    if (msg is Map) return ActionResult.fromApiMap(_asMap(msg));
    if (msg is String && msg.trim().isNotEmpty) {
      return ActionResult.ok(message: msg.trim());
    }
    return ActionResult.failure('Unknown response format');
  }

  @override
  Future<List<BuyerOption>> fetchBuyers({required String token}) async {
    final decoded = await _client.getMobile(
      'get_buyers',
      query: {'token': token},
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    final map = msg is Map ? _asMap(msg) : decoded;
    return BuyerOptionMapper.fromList(map['buyers']);
  }

  @override
  Future<List<CustomerOption>> fetchCustomers({
    required String token,
    required String company,
    String? searchText,
  }) async {
    if (company.trim().isEmpty) return const [];
    final filters = [
      ['custom_company', '=', company],
      ['disabled', '=', 0],
    ];
    final query = <String, String>{
      'doctype': 'Customer',
      'fields': jsonEncode(['name', 'customer_name', 'custom_company']),
      'filters': jsonEncode(filters),
      'limit_page_length': '50',
      'order_by': 'customer_name asc',
    };
    final q = searchText?.trim() ?? '';
    if (q.isNotEmpty) {
      query['or_filters'] = jsonEncode([
        ['name', 'like', '%$q%'],
        ['customer_name', 'like', '%$q%'],
      ]);
    }
    final uri = Uri.parse('${ApiConfig.apiMethodPath}frappe.client.get_list')
        .replace(queryParameters: query);
    final decoded = await _client.getJson(
      uri,
      headers: {'Cookie': 'sid=$token'},
    );
    final msg = _client.unwrap(decoded);
    final raw = msg is List
        ? msg
        : (msg is Map ? msg['data'] : decoded['message']);
    return CustomerOptionMapper.fromList(raw);
  }

  @override
  Future<List<SupplierOption>> fetchSuppliers({
    required String token,
    String? company,
    String? searchText,
  }) async {
    final query = <String, String>{'token': token};
    if (company != null && company.isNotEmpty) query['company'] = company;
    if (searchText != null && searchText.trim().isNotEmpty) {
      query['search_text'] = searchText.trim();
    }
    final decoded = await _client.getMobile(
      'get_suppliers',
      query: query,
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    final map = msg is Map ? _asMap(msg) : decoded;
    return SupplierOptionMapper.fromList(map['suppliers']);
  }

  @override
  Future<CommandeManqueListResponse> fetchCommandes({
    required String token,
    int limit = 50,
    int offset = 0,
    String? searchText,
    String status = 'All',
  }) async {
    final query = <String, String>{
      'token': token,
      'limit': '$limit',
      'offset': '$offset',
      'status': status,
    };
    if (searchText != null && searchText.trim().isNotEmpty) {
      query['search_text'] = searchText.trim();
    }
    final decoded = await _client.getMobile(
      'get_commandes_de_manque',
      query: query,
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    final map = msg is Map ? _asMap(msg) : decoded;
    return CommandeManqueListMapper.fromJson(map, limit: limit, offset: offset);
  }

  @override
  Future<CommandeDeManque> fetchCommandeDetail({
    required String token,
    required String name,
  }) async {
    final decoded = await _client.getMobile(
      'get_commande_de_manque_detail',
      query: {'token': token, 'name': name},
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    final map = msg is Map ? _asMap(msg) : decoded;
    final err = map['error']?.toString();
    if (err != null && err.isNotEmpty && map['success'] != true) {
      throw RepositoryException(err);
    }
    final raw = map['commande'] ?? map;
    if (raw is! Map) {
      throw const RepositoryException('Invalid commande detail');
    }
    return CommandeDeManqueMapper.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
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
  }) async {
    try {
      final decoded = await _client.postMobile(
        'create_commande_de_manque',
        body: {
          'token': token,
          'company': company,
          'warehouse': warehouse,
          'buyer': buyer,
          'customer': customer,
          'customer_name': customerName,
          if (transactionDate != null && transactionDate.isNotEmpty)
            'transaction_date': transactionDate,
          'items': items,
          'envoyer': envoyer ? 1 : 0,
        },
        attachToken: false,
      );
      final msg = _client.unwrap(decoded);
      if (msg is Map) {
        final map = _asMap(msg);
        final parsed = ActionResult.fromApiMap(map);
        if (parsed.isSuccess) {
          final cmd = map['commande'];
          final name = cmd is Map
              ? cmd['name']?.toString()
              : map['name']?.toString();
          return ActionResult.ok(
            message: parsed.message ?? 'Success',
            documentName: name ?? parsed.documentName,
          );
        }
        if (map['success'] == true || map['commande'] != null) {
          final cmd = map['commande'];
          return ActionResult.ok(
            message: 'Success',
            documentName: cmd is Map ? cmd['name']?.toString() : null,
          );
        }
        return parsed;
      }
      return _actionFrom(msg);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  @override
  Future<ActionResult> manageCommande({
    required String token,
    required String name,
    required String action,
  }) async {
    try {
      final decoded = await _client.postMobile(
        'manage_commande_de_manque',
        body: {'token': token, 'name': name, 'action': action},
        attachToken: false,
      );
      final msg = _client.unwrap(decoded);
      return _actionFrom(msg);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  @override
  Future<FactureAcheteurListResponse> fetchFactures({
    required String token,
    int limit = 50,
    int offset = 0,
    String? searchText,
    String? status,
  }) async {
    final query = <String, String>{
      'token': token,
      'limit': '$limit',
      'offset': '$offset',
    };
    if (searchText != null && searchText.trim().isNotEmpty) {
      query['search_text'] = searchText.trim();
    }
    if (status != null && status.isNotEmpty && status != 'All') {
      query['status'] = status;
    }
    final decoded = await _client.getMobile(
      'get_factures_acheteur',
      query: query,
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    final map = msg is Map ? _asMap(msg) : decoded;
    return FactureAcheteurListMapper.fromJson(map, limit: limit, offset: offset);
  }

  @override
  Future<FactureAcheteur> fetchFactureDetail({
    required String token,
    required String name,
  }) async {
    final decoded = await _client.getMobile(
      'get_facture_acheteur_detail',
      query: {'token': token, 'name': name},
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    final map = msg is Map ? _asMap(msg) : decoded;
    final err = map['error']?.toString();
    if (err != null && err.isNotEmpty && map['success'] != true) {
      throw RepositoryException(err);
    }
    final raw = map['facture'] ?? map;
    if (raw is! Map) {
      throw const RepositoryException('Invalid facture detail');
    }
    return FactureAcheteurMapper.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<ActionResult> createFacture({
    required String token,
    required String commandeDeManque,
  }) async {
    try {
      final decoded = await _client.postMobile(
        'create_facture_acheteur',
        body: {
          'token': token,
          'commande_de_manque': commandeDeManque,
        },
        attachToken: false,
      );
      final msg = _client.unwrap(decoded);
      if (msg is Map) {
        final map = _asMap(msg);
        final facture = map['facture'];
        final name = facture is Map
            ? facture['name']?.toString()
            : map['name']?.toString();
        if (map['success'] == true || facture != null || name != null) {
          return ActionResult.ok(
            message: map['existing'] == true ? 'existing' : 'Success',
            documentName: name,
            detail: map['existing'] == true ? 'existing' : null,
          );
        }
        return ActionResult.fromApiMap(map);
      }
      return _actionFrom(msg);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  @override
  Future<ActionResult> saveFactureDraft({
    required String token,
    required String name,
    required String modeAchat,
    required String supplier,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final decoded = await _client.postMobile(
        'save_facture_acheteur_draft',
        body: {
          'token': token,
          'name': name,
          'mode_achat': modeAchat,
          'supplier': supplier,
          'items': items,
        },
        attachToken: false,
      );
      final msg = _client.unwrap(decoded);
      return _actionFrom(msg);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  @override
  Future<ActionResult> submitFacture({
    required String token,
    required String name,
    required String modeAchat,
    required String supplier,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final decoded = await _client.postMobile(
        'submit_facture_acheteur',
        body: {
          'token': token,
          'name': name,
          'mode_achat': modeAchat,
          'supplier': supplier,
          'items': items,
        },
        attachToken: false,
      );
      final msg = _client.unwrap(decoded);
      return _actionFrom(msg);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  @override
  Future<ActionResult> payFacture({
    required String token,
    required String name,
  }) async {
    try {
      final decoded = await _client.postMobile(
        'pay_facture_acheteur',
        body: {'token': token, 'name': name},
        attachToken: false,
      );
      final msg = _client.unwrap(decoded);
      return _actionFrom(msg);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  @override
  Future<ActionResult> cancelFacture({
    required String token,
    required String name,
  }) async {
    try {
      final decoded = await _client.postMobile(
        'cancel_facture_acheteur',
        body: {'token': token, 'name': name},
        attachToken: false,
      );
      final msg = _client.unwrap(decoded);
      return _actionFrom(msg);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }
}
