import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:optilens/core/network/api_client.dart';
import 'package:optilens/core/services/session_service.dart';
import 'package:optilens/core/services/token_vault.dart';
import 'package:optilens/presentation/controllers/session_controller.dart';
import 'package:optilens/utils/translations/app_translations.dart';
import 'package:optilens/widgets/issue_voice_attachments.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'ticket readers can play a vocal and only editors can remove it',
    (tester) async {
      Get.testMode = true;
      addTearDown(Get.reset);
      SharedPreferences.setMockInitialValues({});
      Get.put(await SessionService(tokenVault: MemoryTokenVault()).init());
      Get.put(SessionController()).token.value = 'test-sid';
      final removals = <Object?>[];
      Get.put(
        ApiClient(
          httpClient: MockClient((request) async {
            expect(
              request.url.path,
              endsWith('mobile_app.api.update_issue_voice'),
            );
            final body = jsonDecode(request.body) as Map;
            expect(body['name'], 'ISSUE-1');
            removals.add(body['removed_voice_ids']);
            return http.Response(
              jsonEncode({
                'message': {'voice_ids': []},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

      Future<void> mount({required bool canRemove}) async {
        await tester.pumpWidget(
          GetMaterialApp(
            locale: const Locale('fr', 'FR'),
            translations: AppTranslations(),
            home: Scaffold(
              body: IssueVoiceAttachments(
                key: ValueKey(canRemove),
                issueName: 'ISSUE-1',
                recordingIds: const ['FILE-1'],
                maxBytes: 0,
                maxBatchBytes: 0,
                canRemove: canRemove,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await mount(canRemove: false);
      final play = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Écouter',
      );
      expect(tester.widget<IconButton>(play).onPressed, isNotNull);
      expect(find.byTooltip('Retirer le vocal'), findsNothing);

      await mount(canRemove: true);
      await tester.tap(find.byTooltip('Retirer le vocal'));
      await tester.pumpAndSettle();
      expect(find.text('Retrait à l’enregistrement'), findsOneWidget);
      expect(removals, isEmpty);
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(removals, [
        ['FILE-1'],
      ]);
      expect(play, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
