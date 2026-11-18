import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:optilens/core/network/api_client.dart';
import 'package:optilens/core/services/session_service.dart';
import 'package:optilens/data/repositories/material_request_repository.dart';
import 'package:optilens/data/repositories/stock_entry_details_repository.dart';
import 'package:optilens/data/repositories/stock_entry_repository.dart';
import 'package:optilens/domain/usecases/material_request_usecases.dart';
import 'package:optilens/domain/usecases/stock_entry_usecases.dart';
import 'package:optilens/presentation/controllers/material_request_controller.dart';
import 'package:optilens/presentation/controllers/stock_summary_controller.dart';
import 'package:optilens/widgets/material_request/create_material_request_sheet.dart';

class _Session extends SessionService {
  @override
  String get authToken => 'test-session';
}

void main() {
  testWidgets('stock loads warehouses across companies when opened', (
    tester,
  ) async {
    Get.testMode = true;
    addTearDown(Get.reset);
    Get.put<SessionService>(_Session());
    final requests = <Uri>[];
    final client = ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request.url);
        final result = request.url.path.endsWith('.get_warehouses')
            ? {
                'warehouses': [
                  {'name': 'WH-A', 'company': 'A'},
                  {'name': 'WH-B', 'company': 'B'},
                ],
              }
            : {'items': []};
        return http.Response(jsonEncode({'message': result}), 200);
      }),
    );
    final controller = Get.put(
      StockSummaryController(
        stock: StockEntryUseCases(
          StockEntryRepositoryImpl(client),
          StockEntryDetailsRepositoryImpl(client),
        ),
        materialRequests: MaterialRequestUseCases(
          MaterialRequestRepositoryImpl(client),
        ),
      ),
    );
    expect(requests, isEmpty);
    await controller.loadPage();
    expect(requests.map((url) => url.path.split('.').last), [
      'get_warehouses',
      'get_stock_summary',
    ]);
    expect(requests.first.queryParameters, {'token': 'test-session'});
    expect(controller.warehouses.toList(), ['All', 'WH-A', 'WH-B']);
  });

  for (final companies in [
    <String>[],
    ['Example'],
  ]) {
    testWidgets('material request form loads options for $companies', (
      tester,
    ) async {
      Get.testMode = true;
      addTearDown(Get.reset);
      Get.put<SessionService>(_Session());
      final requests = <String>[];
      final client = ApiClient(
        httpClient: MockClient((request) async {
          final method = request.url.path.split('.').last;
          requests.add(method);
          final payload = switch (method) {
            'get_material_requests' => {'material_requests': []},
            'get_companies' => {
              'companies': companies.map((c) => {'name': c}).toList(),
            },
            'get_price_lists' => {'price_lists': []},
            'get_warehouses' => {'warehouses': []},
            _ => throw StateError('Unexpected method $method'),
          };
          if (method == 'get_warehouses') {
            expect(request.url.queryParameters['company'], 'Example');
          }
          return http.Response(jsonEncode({'message': payload}), 200);
        }),
      );
      final controller = Get.put(
        MaterialRequestController(
          materialRequests: MaterialRequestUseCases(
            MaterialRequestRepositoryImpl(client),
          ),
        ),
      );
      await tester.pump();
      expect(requests, ['get_material_requests']);

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(body: CreateMaterialRequestSheet(c: controller)),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, [
        'get_material_requests',
        'get_companies',
        'get_price_lists',
        if (companies.isNotEmpty) 'get_warehouses',
      ]);
      final saveButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'save_draft'),
      );
      expect(saveButton.onPressed, companies.isEmpty ? isNull : isNotNull);
    });
  }
}
