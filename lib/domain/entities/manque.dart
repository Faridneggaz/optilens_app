class BuyerOption {
  const BuyerOption({
    required this.name,
    required this.employeeName,
    required this.userId,
    required this.company,
    this.ficheDePoste = '',
  });

  final String name;
  final String employeeName;
  final String userId;
  final String company;
  final String ficheDePoste;

  String get displayName =>
      employeeName.trim().isNotEmpty ? employeeName.trim() : name;
}

class SupplierOption {
  const SupplierOption({
    required this.name,
    required this.supplierName,
    required this.supplierGroup,
    required this.company,
  });

  final String name;
  final String supplierName;
  final String supplierGroup;
  final String company;

  String get displayName =>
      supplierName.trim().isNotEmpty ? supplierName.trim() : name;
}

class CustomerOption {
  const CustomerOption({
    required this.name,
    required this.customerName,
    required this.company,
  });

  final String name;
  final String customerName;
  final String company;

  String get displayName =>
      customerName.trim().isNotEmpty ? customerName.trim() : name;
}

class CommandeManqueItem {
  CommandeManqueItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    this.uom = '',
  });

  final String itemCode;
  String itemName;
  double qty;
  String uom;
}

class CommandeDeManque {
  CommandeDeManque({
    required this.name,
    required this.company,
    required this.warehouse,
    required this.transactionDate,
    required this.buyer,
    required this.buyerName,
    this.customer = '',
    this.customerName = '',
    required this.workflowState,
    required this.docstatus,
    this.factureAcheteur = '',
    this.items = const [],
    this.itemCount = 0,
  });

  final String name;
  final String company;
  final String warehouse;
  final String transactionDate;
  final String buyer;
  final String buyerName;
  String customer;
  String customerName;
  String workflowState;
  int docstatus;
  String factureAcheteur;
  List<CommandeManqueItem> items;
  int itemCount;

  int get displayItemCount =>
      items.isNotEmpty ? items.length : itemCount;

  bool get isDraft {
    final s = workflowState.toLowerCase();
    return s == 'brouillon' || s == 'draft' || docstatus == 0 && s.isEmpty;
  }

  bool get canOpenFacture {
    final s = workflowState.toLowerCase();
    return s == 'envoyée' ||
        s == 'envoyee' ||
        s == 'en cours' ||
        s.contains('envoy') ||
        s.contains('cours');
  }
}

class CommandeManqueListResponse {
  const CommandeManqueListResponse({
    required this.commandes,
    this.hasMore = false,
    this.limit = 50,
    this.offset = 0,
  });

  final List<CommandeDeManque> commandes;
  final bool hasMore;
  final int limit;
  final int offset;
}

class FactureAcheteurItem {
  FactureAcheteurItem({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    this.uom = '',
    this.willBuy = true,
    this.rate = 0,
  });

  final String itemCode;
  final String itemName;
  double qty;
  String uom;
  bool willBuy;
  double rate;

  double get amount => willBuy ? qty * rate : 0;
}

class FactureAcheteur {
  FactureAcheteur({
    required this.name,
    required this.commandeDeManque,
    required this.buyer,
    required this.buyerName,
    this.customer = '',
    this.customerName = '',
    required this.modeAchat,
    required this.supplier,
    required this.supplierName,
    required this.currency,
    required this.total,
    required this.workflowState,
    required this.docstatus,
    this.paidOn = '',
    this.paidBy = '',
    this.items = const [],
  });

  final String name;
  final String commandeDeManque;
  final String buyer;
  final String buyerName;
  String customer;
  String customerName;
  String modeAchat;
  String supplier;
  String supplierName;
  String currency;
  double total;
  String workflowState;
  int docstatus;
  String paidOn;
  String paidBy;
  List<FactureAcheteurItem> items;

  bool get isPoche {
    final m = modeAchat.toLowerCase();
    return m.contains('poche') || m.isEmpty;
  }

  bool get isCredit {
    final m = modeAchat.toLowerCase();
    return m.contains('crédit') || m.contains('credit') || m.contains('fournisseur');
  }

  bool get isDraft {
    final s = workflowState.toLowerCase();
    return s == 'brouillon' || s == 'draft' || (docstatus == 0 && !s.contains('valid'));
  }

  bool get isValidee {
    final s = workflowState.toLowerCase();
    return s.contains('valid');
  }

  bool get isRembourse {
    final s = workflowState.toLowerCase();
    return s.contains('rembours');
  }

  bool get canPay => isPoche && isValidee && !isRembourse;
}

class FactureAcheteurListResponse {
  const FactureAcheteurListResponse({
    required this.factures,
    this.hasMore = false,
    this.limit = 50,
    this.offset = 0,
  });

  final List<FactureAcheteur> factures;
  final bool hasMore;
  final int limit;
  final int offset;
}
