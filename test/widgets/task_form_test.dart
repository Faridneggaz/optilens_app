import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:optilens/domain/entities/task.dart';
import 'package:optilens/domain/usecases/task_usecases.dart';
import 'package:optilens/presentation/controllers/task_controller.dart';
import 'package:optilens/utils/translations/app_translations.dart';
import 'package:optilens/widgets/task/task_form_sheet.dart';
import 'package:optilens/widgets/task/pick_assignable_user_sheet.dart';
import '../presentation/task_controller_test.dart' show FakeTasks;

void main() {
  testWidgets(
    'Task form keeps multiple users and stays scrollable above keyboard',
    (tester) async {
      Get.testMode = true;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final controller = TaskController(
        tasks: TaskUseCases(FakeTasks()),
        tokenProvider: () => 'sid',
      );
      controller.listUser.value = 'a@example.com';
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('fr', 'FR'),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: TaskFormSheet(
              controller: controller,
              task: const ErpTask(
                name: 'TASK-1',
                subject: 'Inventory',
                priority: 'Urgent',
                progress: 35.5,
                canWrite: true,
                assignees: [
                  AssignableUser(email: 'a@example.com', fullName: 'Alice'),
                  AssignableUser(email: 'b@example.com', fullName: 'Bob'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Urgente'), findsOneWidget);
      expect(find.text('35.5'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Alice'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Bob'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.onClose();
      Get.reset();
    },
  );
  testWidgets(
    'native User picker fits above the keyboard and selects a User name',
    (tester) async {
      Get.testMode = true;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final controller = TaskController(
        tasks: TaskUseCases(FakeTasks()),
        tokenProvider: () => 'sid',
      );
      late BuildContext pageContext;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('fr', 'FR'),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Builder(
              builder: (context) {
                pageContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      final selection = showAssignableUserPicker(
        context: pageContext,
        controller: controller,
      );
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();
      expect((await selection)?.email, 'b@example.com');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.onClose();
      Get.reset();
    },
  );
}
