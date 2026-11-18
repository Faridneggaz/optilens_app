import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:optilens/core/network/api_client.dart';
import 'package:optilens/data/repositories/invoice_repository.dart';
import 'package:optilens/data/repositories/customer_repository.dart';
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
            '{"message":{"user":{"sid":"abc","email":"a@b.c","name":"Ada"}}}',
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
      late Map payload;
      final client = ApiClient(
        httpClient: MockClient((request) async {
          captured = request.url;
          payload = jsonDecode(request.body) as Map;
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
      expect(captured.queryParameters, isEmpty);
      expect(payload['code'], 'C1');
      expect(payload['search_text'], 'INV');
      expect(payload['status'], 'Unpaid');
      expect(captured.queryParameters.containsKey('token'), isFalse);
    });
  });

  group('OrderRepository', () {
    test('login exchanges a personal code and only orders receive the customer session header', () async {
      String? customerSession;
      final calls = <http.Request>[];
      final client = ApiClient(
        customerSessionProvider: () => customerSession,
        httpClient: MockClient((request) async {
          calls.add(request);
          final payload = switch (request.url.path.split('.').last) {
            'login_customer' => {'customer_session': 'session-a', 'customer': {
              'name': 'A', 'custom_customer_code': 'code-a', 'custom_debt': 0.0,
            }},
            'get_customer_orders' => {'orders': []},
            'get_order_details' => {'status': 'success', 'items': []},
            'create_sales_order' => {'status': 'success', 'order_id': 'SO-1'},
            'logout_customer' => {'success': true},
            _ => throw StateError('Unexpected method'),
          };
          return http.Response(jsonEncode({'message': payload}), 200);
        }),
      );
      final customers = CustomerRepositoryImpl(client);
      final orders = OrderRepositoryImpl(client);
      customerSession = (await customers.loginCustomer('code-a')).sessionToken;
      await orders.fetchOrders();
      await orders.getOrderItems('SO-1');
      await orders.submitOrder(items: [{'item_code': 'TEST', 'qty': 1}]);
      await customers.logoutCustomer();
      expect(calls.first.method, 'POST');
      expect(jsonDecode(calls.first.body), {'code': 'code-a'});
      expect(calls.first.headers.containsKey('X-Mobile-Customer-Session'), isFalse);
      for (final request in calls) {
        expect(request.url.toString(), isNot(contains('code-a')));
        expect(request.url.toString(), isNot(contains('session-a')));
      }
      for (final request in calls.skip(1)) {
        expect(request.headers['X-Mobile-Customer-Session'], 'session-a');
        expect(request.body, isNot(contains('code-a')));
      }
    });

    test('fetchItems reads the success payload', () async {
      final client = ApiClient(
        tokenProvider: () => 'sid',
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters, isEmpty);
          expect(jsonDecode(request.body)['customer_code'], 'C1');
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
