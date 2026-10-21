import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optilens/domain/entities/task.dart';
import 'package:optilens/domain/failures/failures.dart';
import 'package:optilens/domain/usecases/task_usecases.dart';
import 'package:optilens/presentation/controllers/task_controller.dart';
import 'package:optilens/presentation/controllers/language_controller.dart';
import 'package:optilens/utils/translations/app_translations.dart';
import 'package:optilens/views/user/tasks_page.dart';
import 'package:optilens/core/theme/app_theme.dart';
import '../presentation/task_controller_test.dart' show FakeTasks;

const response = TaskListResponse(
  user: 'a@example.com',
  date: '2026-10-21',
  canCreate: true,
  summary: TaskSummary(
    totalItems: 2,
    openCount: 1,
    workingCount: 1,
    overdueCount: 1,
  ),
  tasks: [
    ErpTask(
      name: 'TASK-2026-00014',
      subject: 'Vérifier le stock des verres',
      status: 'Working',
      priority: 'Urgent',
      progress: 45,
      endDate: '2026-10-22',
      assignees: [
        AssignableUser(email: 'a@example.com', fullName: 'Alice'),
        AssignableUser(email: 'b@example.com', fullName: 'Bob'),
      ],
    ),
    ErpTask(
      name: 'TASK-2026-00013',
      subject: 'Préparer la commande client',
      status: 'Open',
      priority: 'Medium',
      isOverdue: true,
      endDate: '2026-10-20',
      assignees: [AssignableUser(email: 'a@example.com', fullName: 'Alice')],
    ),
  ],
);

void main() {
  setUpAll(() async {
    final fonts = Platform.environment['TASK_FONT_DIR'];
    if (fonts == null) return;
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('$fonts/${entry.value}').readAsBytesSync(),
            ),
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

  Future<TaskController> mount(
    WidgetTester tester,
    FakeTasks repo, {
    Locale locale = const Locale('fr', 'FR'),
    VoidCallback? afterFirstFrame,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put(LanguageController());
    final c = Get.put(
      TaskController(tasks: TaskUseCases(repo), tokenProvider: () => 'sid'),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        locale: locale,
        translations: AppTranslations(),
        theme: AppTheme.light(),
        home: RepaintBoundary(
          key: const Key('task-screen'),
          child: const TasksPage(),
        ),
      ),
    );
    afterFirstFrame?.call();
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('list stays compact; status and employee picker remain usable', (
    tester,
  ) async {
    final repo = FakeTasks()
      ..requests.addAll(List.generate(5, (_) => Future.value(response)));
    final c = await mount(tester, repo);
    expect(find.text('Vérifier le stock des verres'), findsOneWidget);
    expect(find.text('Tâches (2)'), findsOneWidget);
    expect(find.text('Alice · Bob'), findsOneWidget);
    expect(find.text('Rechercher un employé...'), findsNothing);
    await tester.tap(find.text('Tâches accessibles'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filtrer par statut'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<TaskListFilter>, 'À valider'),
    );
    await tester.pumpAndSettle();
    expect(c.filter.value, TaskListFilter.review);
    await tester.tap(find.text('Employé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(c.allocatedToFilter.value, 'b@example.com');
    expect(tester.takeException(), isNull);
    // Optional local visual review, not a platform-dependent golden assertion.
    if (Platform.environment['TASK_SCREENSHOT'] == '1') {
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/optilensss.png'),
          tester.element(find.byType(TasksPage)),
        ),
      );
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('task-screen')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/task-screen.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Arabic controls remain usable on a small screen with keyboard', (
    tester,
  ) async {
    final repo = FakeTasks()
      ..requests.addAll(List.generate(3, (_) => Future.value(response)));
    final c = await mount(tester, repo, locale: const Locale('ar', 'DZ'));
    tester.view.physicalSize = const Size(320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    c.scope.value = 'accessible';
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(TaskListControls))),
      TextDirection.rtl,
    );
    await tester.enterText(find.byType(TextField), 'stock');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(c.searchQuery.value, 'stock');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed request shows retry without misleading zero counters', (
    tester,
  ) async {
    final pending = Completer<TaskListResponse>();
    final repo = FakeTasks()
      ..requests.addAll([pending.future, Future.value(response)]);
    // Mount only one frame while the response is pending.
    await mount(
      tester,
      repo,
      afterFirstFrame: () => pending.completeError(
        const RepositoryException('Server unavailable'),
      ),
    );
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Tâches (0)'), findsNothing);
    expect(find.text('Nouvelle tâche'), findsNothing);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Vérifier le stock des verres'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
