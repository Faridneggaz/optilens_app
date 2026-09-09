import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_routes.dart';
import 'app/routes/app_pages.dart';
import 'application/controllers/session_controller.dart';
import 'application/controllers/language_controller.dart';
import 'utils/translations/app_translations.dart';
import 'core/services/session_service.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'app/bindings/repository_binding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Get.putAsync(() => SessionService().init());
  Get.put(
    ApiClient(tokenProvider: () => Get.find<SessionService>().getSid()),
    permanent: true,
  );
  RepositoryBinding.register();
  Get.put(SessionController(), permanent: true);
  Get.put(LanguageController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionService = Get.find<SessionService>();
    final lc = Get.find<LanguageController>();
    final initial = sessionService.isSessionValid()
        ? AppRoutes.main
        : AppRoutes.login;

    return Obx(() {
      final locale = lc.current.value.locale;
      final isRtl = lc.current.value.languageCode == 'ar';

      return GetMaterialApp(
        title: 'Optilens',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        translations: AppTranslations(),
        locale: locale,
        fallbackLocale: const Locale('fr', 'FR'),
        builder: (ctx, child) => Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
        initialRoute: initial,
        getPages: AppPages.pages,
      );
    });
  }
}
