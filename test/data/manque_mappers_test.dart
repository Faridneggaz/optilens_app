import 'package:flutter_test/flutter_test.dart';
import 'package:optilens/data/mappers/manque_mappers.dart';
import 'package:optilens/utils/manque_status_helper.dart';

void main() {
  group('BuyerOptionMapper', () {
    test('maps buyer with fiche de poste', () {
      final buyer = BuyerOptionMapper.fromJson({
        'name': 'HR-EMP-00008',
        'employee_name': 'Chakir Belaouane',
        'user_id': 'chakir@optilens.dz',
        'company': 'OPTILENS ALGER',
        'fiche_de_poste': 'FP-Acheteur Démarcheur (Local)',
      });
      expect(buyer.name, 'HR-EMP-00008');
      expect(buyer.displayName, 'Chakir Belaouane');
      expect(buyer.ficheDePoste, 'FP-Acheteur Démarcheur (Local)');
    });

    test('skips empty names in list', () {
      final list = BuyerOptionMapper.fromList([
        {'name': '', 'employee_name': 'X'},
        {
          'name': 'HR-EMP-00008',
          'employee_name': 'Chakir Belaouane',
        },
      ]);
      expect(list.length, 1);
      expect(list.first.name, 'HR-EMP-00008');
    });
  });

  group('CommandeDeManqueMapper', () {
    test('maps customer and items', () {
      final cmd = CommandeDeManqueMapper.fromJson({
        'name': 'CM-2026-00007',
        'company': 'OPTILENS ALGER',
        'warehouse': 'Magasins - OA',
        'transaction_date': '2026-10-06',
        'buyer': 'HR-EMP-00008',
        'buyer_name': 'Chakir Belaouane',
        'customer': '#OUSSAMA',
        'customer_name': 'Oussama',
        'workflow_state': 'Envoyée',
        'docstatus': 0,
        'items': [
          {
            'item_code': 'C Gry MC -1.25 -0.00',
            'item_name': 'verre',
            'qty': 2,
            'uom': 'Nos',
          },
        ],
      });
      expect(cmd.customer, '#OUSSAMA');
      expect(cmd.customerName, 'Oussama');
      expect(cmd.canOpenFacture, isTrue);
      expect(cmd.items.single.qty, 2);
    });
  });

  group('FactureAcheteurMapper', () {
    test('maps will_buy and totals fields', () {
      final f = FactureAcheteurMapper.fromJson({
        'name': 'FA-0001',
        'commande_de_manque': 'CM-2026-00007',
        'buyer': 'HR-EMP-00008',
        'buyer_name': 'Chakir Belaouane',
        'customer': '#OUSSAMA',
        'customer_name': 'Oussama',
        'mode_achat': 'Poche',
        'supplier': '',
        'supplier_name': '',
        'currency': 'DZD',
        'total': 1500,
        'workflow_state': 'Validée',
        'docstatus': 1,
        'items': [
          {
            'item_code': 'C Gry MC -1.25 -0.00',
            'item_name': 'verre',
            'qty': 2,
            'will_buy': 1,
            'rate': 750,
          },
          {
            'item_code': 'SKIP',
            'item_name': 'skip',
            'qty': 1,
            'will_buy': 0,
            'rate': 0,
          },
        ],
      });
      expect(f.isPoche, isTrue);
      expect(f.canPay, isTrue);
      expect(f.customerName, 'Oussama');
      expect(f.items.first.amount, 1500);
      expect(f.items.last.amount, 0);
    });
  });

  test('modeAchat constants and helpers', () {
    expect(modeAchatPoche, 'Poche');
    expect(modeAchatCredit, 'Crédit fournisseur');
    expect(manqueStatusColor('Brouillon'), isNotNull);
    expect(manqueStatusColor('Annulée'), isNotNull);
  });
}
