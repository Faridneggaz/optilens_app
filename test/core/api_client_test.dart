import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:optilens/core/network/api_client.dart';
import 'package:optilens/data/repositories/announcement_repository.dart';
import 'package:optilens/data/repositories/complaint_repository.dart';
import 'package:optilens/data/repositories/invoice_detail_repository.dart';
import 'package:optilens/data/repositories/invoice_repository.dart';
import 'package:optilens/data/repositories/customer_repository.dart';
import 'package:optilens/data/repositories/login_repository.dart';
import 'package:optilens/data/repositories/material_request_repository.dart';
import 'package:optilens/data/repositories/notification_repository.dart';
import 'package:optilens/data/repositories/order_repository.dart';
import 'package:optilens/data/repositories/payment_repository.dart';
import 'package:optilens/data/repositories/stock_entry_details_repository.dart';
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
        'get_last_stock_entries',
        query: {'limit': '5'},
      );

      expect(json['message'], {'ok': true});
      expect(captured.path, '/api/method/mobile_app.api.get_last_stock_entries');
      expect(captured.queryParameters['limit'], '5');
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

  group('Customer profile', () {
    test('reads the profile using only the customer session and keeps the stored code local', () async {
      final client = ApiClient(
        tokenProvider: () => 'employee-sid',
        customerSessionProvider: () => 'customer-session',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/method/mobile_app.api.get_customer_profile');
          expect(request.url.queryParameters, isEmpty);
          expect(request.body, isEmpty);
          expect(request.headers['X-Mobile-Customer-Session'], 'customer-session');
          expect(request.headers.values, isNot(contains('stored-code')));
          return http.Response(
            '{"message":{"customer":{"name":"Customer A","custom_debt":12.5,"mobile_no":"123"}}}',
            200,
          );
        }),
      );
      final result = await CustomerRepositoryImpl(client).fetchCustomer('stored-code');
      expect(result.customer.name, 'Customer A');
      expect(result.customer.code, 'stored-code');
      expect(result.customer.debt, 12.5);
      expect(result.customer.mobile, '123');
    });

    test('rejects an expired session without retrying with the stored code', () async {
      var calls = 0;
      final client = ApiClient(httpClient: MockClient((request) async {
        calls++;
        return http.Response('{"message":{"error":"Invalid session"}}', 200);
      }));
      await expectLater(
        CustomerRepositoryImpl(client).fetchCustomer('stored-code'),
        throwsA(isA<InvalidSessionException>()),
      );
      expect(calls, 1);
    });
  });

  group('InvoiceRepository', () {
    test('loads sales and POS lists with the customer session and selected filters', () async {
      final client = ApiClient(
        tokenProvider: () => 'employee-session',
        customerSessionProvider: () => 'customer-session',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/method/mobile_app.api.get_customer_invoices');
          expect(request.url.queryParameters, {
            'limit': '5', 'offset': '10', 'search_text': 'INV', 'status': 'Unpaid',
          });
          expect(request.headers['X-Mobile-Customer-Session'], 'customer-session');
          expect(request.body, isEmpty);
          return http.Response(
            '{"message":{"sales_invoices":['
            '{"name":"INV-1","posting_date":"2026-01-01","grand_total":10,'
            '"outstanding_amount":2,"status":"Unpaid","is_pos":0}'
            '],"pos_invoices":[{"name":"POS-1","posting_date":"2026-01-01",'
            '"grand_total":15,"outstanding_amount":0,"status":"Paid","is_pos":1}],'
            '"is_search":true}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await InvoiceRepositoryImpl(client).fetchInvoices(
        limit: 5,
        offset: 10,
        searchText: 'INV',
        status: 'Unpaid',
      );

      expect(result.salesInvoices, hasLength(1));
      expect(result.salesInvoices.first.name, 'INV-1');
      expect(result.posInvoices.single.name, 'POS-1');
      expect(result.isSearch, isTrue);
    });

    test('opens an invoice with the session and surfaces an unavailable invoice', () async {
      final client = ApiClient(
        tokenProvider: () => 'employee-session',
        customerSessionProvider: () => 'customer-session',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/method/mobile_app.api.get_single_invoice_details');
          expect(request.headers['X-Mobile-Customer-Session'], 'customer-session');
          expect(request.url.queryParameters.keys, ['invoice_name']);
          final name = request.url.queryParameters['invoice_name'];
          final message = name == 'INV-1'
              ? {'invoice': {'name': name}, 'items': [{'item_code': 'LENS'}]}
              : {'error': 'Invoice not found'};
          return http.Response(jsonEncode({'message': message}), 200);
        }),
      );
      final repository = InvoiceDetailRepositoryImpl(client);
      final result = await repository.getInvoiceDetails(invoiceName: 'INV-1');
      expect(result.invoice.name, 'INV-1');
      expect(result.items.single.itemCode, 'LENS');
      await expectLater(
        repository.getInvoiceDetails(invoiceName: 'MISSING'),
        throwsA(isA<RepositoryException>().having(
          (e) => e.message, 'message', 'Invoice not found',
        )),
      );
    });

    test('reports an expired session for the invoice list and detail', () async {
      final client = ApiClient(
        httpClient: MockClient((_) async =>
            http.Response('{"message":{"error":"Invalid session"}}', 200)),
      );
      await expectLater(InvoiceRepositoryImpl(client).fetchInvoices(),
          throwsA(isA<InvalidSessionException>()));
      await expectLater(InvoiceDetailRepositoryImpl(client).getInvoiceDetails(invoiceName: 'INV-1'),
          throwsA(isA<InvalidSessionException>()));
    });
  });

  group('Customer payments and complaints', () {
    test('loads a page of payments and linked invoices using the customer session', () async {
      final client = ApiClient(
        tokenProvider: () => 'employee-session',
        customerSessionProvider: () => 'customer-session',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/method/mobile_app.api.get_customer_payments');
          expect(request.url.queryParameters, {'limit': '1', 'offset': '5', 'search_text': 'PAY'});
          expect(request.headers['X-Mobile-Customer-Session'], 'customer-session');
          expect(request.body, isEmpty);
          return http.Response(jsonEncode({
            'message': {
              'payments': [
                {
                  'name': 'PAY-1',
                  'invoices_payed': [
                    {'invoice': 'INV-1', 'allocated_amount': 25}
                  ],
                }
              ],
              'is_search': true,
            }
          }), 200);
        }),
      );
      final page = await PaymentRepositoryImpl(client).fetchPayments(
        limit: 1, offset: 5, searchText: 'PAY',
      );
      expect(page.payments.single.name, 'PAY-1');
      final invoice = page.payments.single.invoicesPayed.single;
      expect(invoice.invoice, 'INV-1');
      expect(invoice.allocatedAmount, 25);
      expect(page.isSearch, isTrue);
      expect(page.hasMore, isTrue);
    });

    test('submits a complaint using only its description and the session header', () async {
      final client = ApiClient(
        customerSessionProvider: () => 'customer-session',
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/method/mobile_app.api.create_customer_complaint');
          expect(request.url.queryParameters, isEmpty);
          expect(request.headers['X-Mobile-Customer-Session'], 'customer-session');
          expect(jsonDecode(request.body), {'description': 'Order incomplete'});
          return http.Response('{"message":{"message":"Success","id":"REC-1"}}', 200);
        }),
      );
      await ComplaintRepositoryImpl(client).submitComplaint(description: 'Order incomplete');
    });

    test('reports expired sessions for payments and complaints', () async {
      final client = ApiClient(httpClient: MockClient((_) async =>
          http.Response('{"message":{"error":"Invalid session"}}', 200)));
      await expectLater(PaymentRepositoryImpl(client).fetchPayments(),
          throwsA(isA<InvalidSessionException>()));
      await expectLater(ComplaintRepositoryImpl(client).submitComplaint(description: 'Test'),
          throwsA(isA<InvalidSessionException>()));
    });

    test('a rejected complaint is not displayed as successful', () async {
      final client = ApiClient(httpClient: MockClient((_) async =>
          http.Response('{"message":{"error":"Unable to create complaint"}}', 200)));
      await expectLater(ComplaintRepositoryImpl(client).submitComplaint(description: 'Test'),
          throwsA(isA<RepositoryException>().having(
            (e) => e.message, 'message', 'Unable to create complaint',
          )));
    });
  });

  group('OrderRepository', () {
    test('login exchanges a personal code for the session used on orders and logout', () async {
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

    test('fetchItems reads the customer catalog using the session header', () async {
      final client = ApiClient(
        tokenProvider: () => 'sid',
        customerSessionProvider: () => 'customer-session',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/method/mobile_app.api.get_customer_items');
          expect(request.url.queryParameters, isEmpty);
          expect(request.body, isEmpty);
          expect(request.headers['X-Mobile-Customer-Session'], 'customer-session');
          return http.Response(
            '{"message":{"status":"success","items":['
            '{"item_code":"X","item_name":"Lens","rate":12.5}'
            ']}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final items = await OrderRepositoryImpl(client).fetchItems();
      expect(items, hasLength(1));
      expect(items.first.itemCode, 'X');
      expect(items.first.rate, 12.5);
    });
  });

  group('Customer communications and item search', () {
    test('sends only the session and the requested page or search parameters', () async {
      final client = ApiClient(
        tokenProvider: () => 'employee-sid',
        customerSessionProvider: () => 'customer-session',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.body, isEmpty);
          expect(request.headers['X-Mobile-Customer-Session'], 'customer-session');
          final method = request.url.path.split('.').last;
          if (method == 'get_customer_notifications') {
            expect(request.url.queryParameters, isEmpty);
            return http.Response('{"message":{"notification":[{"title":"Hello"}]}}', 200);
          }
          if (method == 'get_customer_announcements') {
            expect(request.url.queryParameters, {'limit': '2', 'offset': '4'});
            return http.Response('{"message":{"announcements":[{"id":"ANN","title":"Update"}]}}', 200);
          }
          expect(method, 'search_customer_items');
          expect(request.url.queryParameters, {'search_text': 'Lens'});
          return http.Response('{"message":[{"item_code":"ITEM","standard_rate":9}]}', 200);
        }),
      );
      final notes = await NotificationRepositoryImpl(client).fetchNotifications();
      final page = await AnnouncementRepositoryImpl(client).fetchAnnouncements(limit: 2, offset: 4);
      final items = await OrderRepositoryImpl(client).searchItems(searchText: 'Lens');
      expect(notes.single['title'], 'Hello');
      expect(page.single.title, 'Update');
      expect(items.single.rate, 9);
    });

    test('expired sessions reach the caller for all four customer reads', () async {
      final client = ApiClient(httpClient: MockClient((_) async =>
          http.Response('{"message":{"error":"Invalid session"}}', 200)));
      final orders = OrderRepositoryImpl(client);
      for (final read in [
        () => NotificationRepositoryImpl(client).fetchNotifications(),
        () => AnnouncementRepositoryImpl(client).fetchAnnouncements(),
        () => orders.fetchItems(),
        () => orders.searchItems(searchText: 'Lens'),
      ]) {
        await expectLater(read(), throwsA(isA<InvalidSessionException>()));
      }
    });

    test('both employee screens search with the ERP session', () async {
      final client = ApiClient(
        customerSessionProvider: () => 'customer-session',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/method/mobile_app.api.search_employee_items');
          expect(request.method, 'POST');
          expect(request.url.queryParameters, isEmpty);
          expect(request.headers.containsKey('X-Mobile-Customer-Session'), isFalse);
          expect(jsonDecode(request.body), {'token': 'erp-sid', 'search_text': 'Lens'});
          return http.Response('{"message":[{"item_code":"X","item_name":"Lens"}]}', 200);
        }),
      );
      for (final search in [
        StockEntryDetailsRepositoryImpl(client).searchItems,
        MaterialRequestRepositoryImpl(client).searchItems,
      ]) {
        final items = await search(token: 'erp-sid', searchText: 'Lens');
        expect(items.single, {'item_code': 'X', 'item_name': 'Lens'});
      }
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
