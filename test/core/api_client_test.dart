import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:optilens/core/network/api_client.dart';
import 'package:optilens/data/repositories/invoice_repository.dart';
import 'package:optilens/data/repositories/login_repository.dart';
import 'package:optilens/data/repositories/order_repository.dart';
import 'package:optilens/domain/failures/failures.dart';
import 'package:optilens/utils/api_config.dart';
import 'package:optilens/utils/error_feedback.dart';

void main() {
  group('ApiClient', () {
    test('getMobile parses Frappe JSON and attaches the session token', () async {
      late Uri captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request.url;
          return http.Response(
            '{"message":{"ok":true}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        tokenProvider: () => 'sid-123',
      );

      final json = await client.getMobile(
        'get_client_by_code',
        query: {'code': 'C001'},
      );

      expect(json['message'], {'ok': true});
      expect(captured.path, '/api/method/mobile_app.api.get_client_by_code');
      expect(captured.queryParameters['code'], 'C001');
      expect(captured.queryParameters['token'], 'sid-123');
      expect(captured.origin, ApiConfig.baseUrl);
    });

    test('throws RepositoryException on non-200', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async => http.Response('nope', 500)),
      );

      expect(
        () => client.getMobile('login', attachToken: false),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('postErpResource fails when ERP_API_TOKEN is not configured', () async {
      final client = ApiClient(httpClient: MockClient((request) async {
        fail('should not call the network');
      }));

      expect(
        () => client.postErpResource('Lead', {'lead_name': 'A'}),
        throwsA(
          isA<RepositoryException>().having(
            (e) => e.message,
            'message',
            contains('not configured'),
          ),
        ),
      );
    });
  });

  group('LoginRepository', () {
    test('maps a successful Frappe login payload', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          return http.Response(
            '{"message":{"user":{"sid":"abc","email":"a@b.c","name":"Ada",'
            '"allowed_companies":[],"allowed_warehouses":[]}}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await LoginRepositoryImpl(client).login(
        email: 'a@b.c',
        password: 'secret',
      );

      expect(result.user.sid, 'abc');
    });

    test('throws when Frappe returns ok:false', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async {
          return http.Response(
            '{"message":{"ok":false,"error":"bad credentials"}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      expect(
        () => LoginRepositoryImpl(client).login(email: 'a', password: 'b'),
        throwsA(isA<RepositoryException>()),
      );
    });
  });

  group('InvoiceRepository', () {
    test('fetchInvoices maps sales and POS lists', () async {
      late Uri captured;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request.url;
          return http.Response(
            '{"message":{"customer_code":"C1","sales_invoices":['
            '{"name":"INV-1","posting_date":"2026-01-01","grand_total":10,'
            '"outstanding_amount":2,"status":"Unpaid","is_pos":0}'
            '],"pos_invoices":[],"is_search":false}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await InvoiceRepositoryImpl(client).fetchInvoices(
        'C1',
        searchText: 'INV',
        status: 'Unpaid',
      );

      expect(result.salesInvoices, hasLength(1));
      expect(result.salesInvoices.first.name, 'INV-1');
      expect(captured.queryParameters['code'], 'C1');
      expect(captured.queryParameters['search_text'], 'INV');
      expect(captured.queryParameters['status'], 'Unpaid');
      expect(captured.queryParameters.containsKey('token'), isFalse);
    });
  });

  group('OrderRepository', () {
    test('fetchItems reads the success payload', () async {
      final client = ApiClient(
        tokenProvider: () => 'sid',
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters['token'], 'sid');
          expect(request.url.queryParameters['customer_code'], 'C1');
          return http.Response(
            '{"message":{"status":"success","items":['
            '{"item_code":"X","item_name":"Lens","rate":12.5}'
            ']}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final items = await OrderRepositoryImpl(client).fetchItems('C1');
      expect(items, hasLength(1));
      expect(items.first.itemCode, 'X');
      expect(items.first.rate, 12.5);
    });
  });

  group('ErrorFeedback', () {
    test('detects network and timeout repository errors', () {
      expect(
        ErrorFeedback.isNetwork(const RepositoryException('Request timeout')),
        isTrue,
      );
      expect(
        ErrorFeedback.isNetwork(const RepositoryException('Network error: x')),
        isTrue,
      );
      expect(
        ErrorFeedback.isNetwork(const RepositoryException('Login failed')),
        isFalse,
      );
    });
  });
}
