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
}
