import 'package:flutter_test/flutter_test.dart';
import 'package:optilens/data/mappers/json_mappers.dart';

void main() {
  test('ItemMapper maps Frappe item fields', () {
    final item = ItemMapper.fromJson({
      'item_code': 'GL-1',
      'item_name': 'Glass',
      'standard_rate': '12.5',
      'currency': 'DZD',
      'uom': 'Nos',
    });
    expect(item.itemCode, 'GL-1');
    expect(item.itemName, 'Glass');
    expect(item.rate, 12.5);
  });

  test('LoginResponseMapper reads nested user SID', () {
    final login = LoginResponseMapper.fromJson({
      'message': {
        'user': {
          'sid': 'abc',
          'email': 'a@b.c',
          'name': 'Ada',
        },
      },
    });
    expect(login.user.sid, 'abc');
    expect(login.user.email, 'a@b.c');
  });

  test('StockEntryResponseMapper reads nested last_stock_entries', () {
    final response = StockEntryResponseMapper.fromJson({
      'message': {
        'success': true,
        'data': {
          'last_stock_entries': [
            {
              'name': 'MAT-STE-2026-0001',
              'posting_date': '2026-09-09',
              'from_warehouse': 'A',
              'to_warehouse': 'B',
              'status': 'Draft',
            }
          ],
        },
      },
    });
    expect(response.stockEntries, hasLength(1));
    expect(response.stockEntries.first.name, 'MAT-STE-2026-0001');
    expect(response.stockEntries.first.from, 'A');
  });

  test('StockSummaryResponseMapper maps totals and items', () {
    final response = StockSummaryResponseMapper.fromJson({
      'success': true,
      'warehouse': '',
      'company': '',
      'summary': {
        'total_items': 2,
        'total_qty': 10,
        'low_stock_count': 1,
      },
      'items': [
        {
          'item_code': 'GL-1',
          'item_name': 'Glass',
          'warehouse': 'WH-1',
          'qty': 3,
          'uom': 'Nos',
          'is_low_stock': true,
          'reorder_level': 5,
        }
      ],
      'has_more': false,
    });
    expect(response.summary.totalItems, 2);
    expect(response.summary.totalQty, 10);
    expect(response.summary.lowStockCount, 1);
    expect(response.items, hasLength(1));
    expect(response.items.first.itemCode, 'GL-1');
    expect(response.items.first.qty, 3);
    expect(response.items.first.isLowStock, isTrue);
  });

  test('StockEntryDetailsResponseMapper accepts snake_case payload', () {
    final response = StockEntryDetailsResponseMapper.fromJson({
      'message': {
        'stock_entry': {
          'name': 'MAT-STE-1',
          'posting_date': '2026-09-13',
          'from_warehouse': 'A',
          'to_warehouse': 'B',
          'company': 'OPTILENS',
          'status': 'Draft',
        },
        'items': [
          {
            'item_code': 'GL-1',
            'item_name': 'Glass',
            'qty': 2,
            's_warehouse': 'A',
            't_warehouse': 'B',
          }
        ],
      },
    });
    expect(response.stockEntry.name, 'MAT-STE-1');
    expect(response.items, hasLength(1));
    expect(response.items.first.itemCode, 'GL-1');
    expect(response.items.first.quantity, 2);
  });
}
