import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

Color manqueStatusColor(String status) {
  final s = status.toLowerCase().trim();
  if (s.contains('brouillon') || s == 'draft') return Colors.blueGrey;
  if (s.contains('envoy')) return Colors.blue;
  if (s.contains('cours')) return Colors.orange;
  if (s.contains('valid')) return Colors.blue.shade700;
  if (s.contains('termin') || s.contains('rembours')) return Colors.green;
  if (s.contains('partiell')) return Colors.orange.shade700;
  if (s.contains('annul')) return Colors.red;
  return Colors.grey;
}

const commandeManqueStatuses = [
  'All',
  'Brouillon',
  'Envoyée',
  'En cours',
  'Terminée',
  'Partielle',
];

const factureAcheteurStatuses = [
  'All',
  'Brouillon',
  'Validée',
  'Remboursée',
  'Annulée',
];

const modeAchatPoche = 'Poche';
const modeAchatCredit = 'Crédit fournisseur';

Color modeAchatColor(String mode) {
  final m = mode.toLowerCase();
  if (m.contains('crédit') || m.contains('credit') || m.contains('fournisseur')) {
    return Colors.deepOrange.shade700;
  }
  return AppColors.primaryDark;
}

IconData modeAchatIcon(String mode) {
  final m = mode.toLowerCase();
  if (m.contains('crédit') || m.contains('credit') || m.contains('fournisseur')) {
    return Icons.storefront_outlined;
  }
  return Icons.account_balance_wallet_outlined;
}
