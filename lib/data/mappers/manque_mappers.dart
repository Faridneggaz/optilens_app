import '../../domain/entities/manque.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

bool _toBool01(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().trim().toLowerCase();
  if (s == '1' || s == 'true' || s == 'yes') return true;
  if (s == '0' || s == 'false' || s == 'no') return false;
  return fallback;
}

class BuyerOptionMapper {
  static List<BuyerOption> fromList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .where((b) => b.name.isNotEmpty)
        .toList();
  }

  static BuyerOption fromJson(Map<String, dynamic> json) => BuyerOption(
        name: json['name']?.toString() ?? '',
        employeeName: json['employee_name']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        company: json['company']?.toString() ?? '',
        ficheDePoste: json['fiche_de_poste']?.toString() ??
            json['custom_fiche_de_poste']?.toString() ??
            '',
      );
}

class CustomerOptionMapper {
  static List<CustomerOption> fromList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.name.isNotEmpty)
        .toList();
  }

  static CustomerOption fromJson(Map<String, dynamic> json) => CustomerOption(
        name: json['name']?.toString() ?? '',
        customerName: json['customer_name']?.toString() ?? '',
        company: json['custom_company']?.toString() ??
            json['company']?.toString() ??
            '',
      );
}

class SupplierOptionMapper {
  static List<SupplierOption> fromList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.name.isNotEmpty)
        .toList();
  }

  static SupplierOption fromJson(Map<String, dynamic> json) => SupplierOption(
        name: json['name']?.toString() ?? '',
        supplierName: json['supplier_name']?.toString() ?? '',
        supplierGroup: json['supplier_group']?.toString() ?? '',
        company: json['company']?.toString() ?? '',
      );
}

class CommandeManqueItemMapper {
  static CommandeManqueItem fromJson(Map<String, dynamic> json) =>
      CommandeManqueItem(
        itemCode: json['item_code']?.toString() ?? '',
        itemName: json['item_name']?.toString() ?? '',
        qty: _toDouble(json['qty']),
        uom: json['uom']?.toString() ?? '',
      );
}

class CommandeDeManqueMapper {
  static CommandeDeManque fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = <CommandeManqueItem>[];
    if (itemsRaw is List) {
      for (final row in itemsRaw) {
        if (row is! Map) continue;
        final item =
            CommandeManqueItemMapper.fromJson(Map<String, dynamic>.from(row));
        if (item.itemCode.isEmpty) continue;
        items.add(item);
      }
    }
    return CommandeDeManque(
      name: json['name']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      warehouse: json['warehouse']?.toString() ?? '',
      transactionDate: json['transaction_date']?.toString() ?? '',
      buyer: json['buyer']?.toString() ?? '',
      buyerName: json['buyer_name']?.toString() ?? '',
      customer: json['customer']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      workflowState: json['workflow_state']?.toString() ?? '',
      docstatus: _toInt(json['docstatus']),
      factureAcheteur: json['facture_acheteur']?.toString() ?? '',
      items: items,
      itemCount: _toInt(json['item_count'] ?? json['items_count']),
    );
  }
}

class CommandeManqueListMapper {
  static CommandeManqueListResponse fromJson(
    Map<String, dynamic> json, {
    int limit = 50,
    int offset = 0,
  }) {
    final raw = json['commandes'] ?? json['data'];
    final list = <CommandeDeManque>[];
    if (raw is List) {
      for (final row in raw) {
        if (row is! Map) continue;
        list.add(
          CommandeDeManqueMapper.fromJson(Map<String, dynamic>.from(row)),
        );
      }
    }
    final hasMore = json['has_more'] == true ||
        json['has_more'] == 1 ||
        (list.length >= limit);
    return CommandeManqueListResponse(
      commandes: list,
      hasMore: hasMore,
      limit: _toInt(json['limit']) > 0 ? _toInt(json['limit']) : limit,
      offset: _toInt(json['offset']),
    );
  }
}

class FactureAcheteurItemMapper {
  static FactureAcheteurItem fromJson(Map<String, dynamic> json) =>
      FactureAcheteurItem(
        itemCode: json['item_code']?.toString() ?? '',
        itemName: json['item_name']?.toString() ?? '',
        qty: _toDouble(json['qty']),
        uom: json['uom']?.toString() ?? '',
        willBuy: _toBool01(json['will_buy'], fallback: true),
        rate: _toDouble(json['rate']),
      );
}

class FactureAcheteurMapper {
  static FactureAcheteur fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = <FactureAcheteurItem>[];
    if (itemsRaw is List) {
      for (final row in itemsRaw) {
        if (row is! Map) continue;
        final item =
            FactureAcheteurItemMapper.fromJson(Map<String, dynamic>.from(row));
        if (item.itemCode.isEmpty) continue;
        items.add(item);
      }
    }
    return FactureAcheteur(
      name: json['name']?.toString() ?? '',
      commandeDeManque: json['commande_de_manque']?.toString() ?? '',
      buyer: json['buyer']?.toString() ?? '',
      buyerName: json['buyer_name']?.toString() ?? '',
      customer: json['customer']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      modeAchat: json['mode_achat']?.toString() ?? 'Poche',
      supplier: json['supplier']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'DZD',
      total: _toDouble(json['total']),
      workflowState: json['workflow_state']?.toString() ?? '',
      docstatus: _toInt(json['docstatus']),
      paidOn: json['paid_on']?.toString() ?? '',
      paidBy: json['paid_by']?.toString() ?? '',
      items: items,
    );
  }
}

class FactureAcheteurListMapper {
  static FactureAcheteurListResponse fromJson(
    Map<String, dynamic> json, {
    int limit = 50,
    int offset = 0,
  }) {
    final raw = json['factures'] ?? json['data'];
    final list = <FactureAcheteur>[];
    if (raw is List) {
      for (final row in raw) {
        if (row is! Map) continue;
        list.add(
          FactureAcheteurMapper.fromJson(Map<String, dynamic>.from(row)),
        );
      }
    }
    final hasMore = json['has_more'] == true ||
        json['has_more'] == 1 ||
        (list.length >= limit);
    return FactureAcheteurListResponse(
      factures: list,
      hasMore: hasMore,
      limit: _toInt(json['limit']) > 0 ? _toInt(json['limit']) : limit,
      offset: _toInt(json['offset']),
    );
  }
}
