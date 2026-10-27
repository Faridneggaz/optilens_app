import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optilens/core/theme/app_theme.dart';
import 'package:optilens/domain/entities/activity_report.dart';
import 'package:optilens/domain/failures/failures.dart';
import 'package:optilens/domain/usecases/activity_report_usecases.dart';
import 'package:optilens/presentation/controllers/activity_report_form_controller.dart';
import 'package:optilens/presentation/controllers/activity_report_list_controller.dart';
import 'package:optilens/presentation/controllers/activity_report_detail_controller.dart';
import 'package:optilens/presentation/controllers/language_controller.dart';
import 'package:optilens/utils/translations/app_translations.dart';
import 'package:optilens/utils/translations/activity_report_translations.dart';
import 'package:optilens/views/activity_report/activity_report_form_page.dart';
import 'package:optilens/views/activity_report/activity_report_list_page.dart';
import 'package:optilens/views/activity_report/activity_report_detail_page.dart';
import 'package:optilens/widgets/activity_report/report_line_editor.dart';
import 'package:optilens/widgets/activity_report/report_widgets.dart';
import '../presentation/activity_report_controller_test.dart'
    show FakeReports;

void main() {
  setUpAll(() async {
    final dir = Platform.environment['REPORT_FONT_DIR'];
    if (dir == null) return;
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(
          Future.value(
            ByteData.sublistView(File('$dir/${entry.value}').readAsBytesSync()),
          ),
        );
      await loader.load();
    }
  });
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(Get.reset);
  Future<void> mount(
    WidgetTester tester,
    Widget page, {
    Locale locale = const Locale('fr', 'FR'),
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    Get.put(LanguageController());
    await tester.pumpWidget(
      GetMaterialApp(
        locale: locale,
        translations: AppTranslations(),
        theme: AppTheme.light(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
          Locale('ar', 'DZ'),
        ],
        home: RepaintBoundary(key: const Key('report-screen'), child: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String filename) async {
    if (Platform.environment['REPORT_SCREENSHOT'] != '1') return;
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/optilensss.png'),
        tester.element(find.byKey(const Key('report-screen'))),
      );
    });
    await tester.pump();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('report-screen')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/$filename.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('all Activity Report translations have the same keys', () {
    expect(activityReportFr.keys.toSet(), activityReportEn.keys.toSet());
    expect(activityReportFr.keys.toSet(), activityReportAr.keys.toSet());
  });
  testWidgets(
    'list shows accessible reports and hides creation for read-only users',
    (tester) async {
      final repo = FakeReports()..canCreate = false;
      Get.put(
        ActivityReportListController(
          reports: ActivityReportUseCases(repo),
          tokenProvider: () => 'sid',
        ),
      );
      await mount(tester, const ActivityReportListPage());
      expect(find.text('Bilan de la semaine'), findsOneWidget);
      expect(find.text('Nouveau rapport'), findsNothing);
      await tester.tap(find.byTooltip('Filtres'));
      await tester.pumpAndSettle();
      expect(find.text('Type de rapport'), findsOneWidget);
      await tester.tap(find.text('Réinitialiser'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('read-only detail displays content but no edit action', (
    tester,
  ) async {
    final repo = FakeReports()..canWrite = false;
    Get.put(
      ActivityReportDetailController(
        reports: ActivityReportUseCases(repo),
        name: 'AR-1',
        tokenProvider: () => 'sid',
      ),
    );
    await mount(tester, const ActivityReportDetailPage());
    expect(find.text('Bilan de la semaine'), findsOneWidget);
    expect(find.byTooltip('Modifier'), findsNothing);
    expect(find.textContaining('Inventaire des verres'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'form preserves changes after network failure and guards leaving',
    (tester) async {
      final repo = FakeReports()
        ..saveError = const RepositoryException('Network error');
      final c = Get.put(
        ActivityReportFormController(
          reports: ActivityReportUseCases(repo),
          name: 'AR-1',
          tokenProvider: () => 'sid',
        ),
      );
      await mount(tester, const ActivityReportFormPage());
      await tester.enterText(find.byType(TextField).first, 'Bilan conservé');
      await tester.pump();
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(find.text('Modifications non enregistrées'), findsOneWidget);
      await tester.tap(find.text('Continuer la saisie'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(c.titleController.text, 'Bilan conservé');
      expect(c.dirty.value, isTrue);
      expect(c.error.value, isNotEmpty);
      expect(repo.saves, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('action editor remains scrollable above a phone keyboard', (
    tester,
  ) async {
    final repo = FakeReports();
    final c = Get.put(
      ActivityReportFormController(
        reports: ActivityReportUseCases(repo),
        tokenProvider: () => 'sid',
      ),
    );
    late BuildContext screenContext;
    await mount(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) {
            screenContext = context;
            return const SizedBox();
          },
        ),
      ),
      size: const Size(320, 640),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    final result = editReportAction(
      screenContext,
      c,
      action: const ReportAction(
        description: 'Vérifier le stock',
        status: 'In Progress',
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Appliquer'),
      140,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect((await result)!.status, 'In Progress');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'Arabic form supports RTL, small screen, keyboard and localized calendar',
    (tester) async {
      final repo = FakeReports();
      Get.put(
        ActivityReportFormController(
          reports: ActivityReportUseCases(repo),
          tokenProvider: () => 'sid',
        ),
      );
      await mount(
        tester,
        const ActivityReportFormPage(),
        locale: const Locale('ar', 'DZ'),
        size: const Size(320, 640),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'تقرير جديد');
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(ActivityReportFormPage))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pump();
      final date = find.byType(ReportDateField).first;
      await tester.ensureVisible(date);
      await tester.tap(
        find.descendant(of: date, matching: find.byType(OutlinedButton)).first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(
        Localizations.localeOf(
          tester.element(find.byType(DatePickerDialog)),
        ).languageCode,
        'ar',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('visual preview of the list and form uses the real app theme', (
    tester,
  ) async {
    final repo = FakeReports();
    Get.put(
      ActivityReportListController(
        reports: ActivityReportUseCases(repo),
        tokenProvider: () => 'sid',
      ),
    );
    await mount(tester, const ActivityReportListPage());
    await capture(tester, 'activity-report-list');
    Get.put(
      ActivityReportFormController(
        reports: ActivityReportUseCases(repo),
        name: 'AR-1',
        tokenProvider: () => 'sid',
      ),
    );
    await mount(tester, const ActivityReportFormPage());
    await capture(tester, 'activity-report-form');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
