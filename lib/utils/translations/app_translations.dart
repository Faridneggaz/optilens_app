import 'activity_report_translations.dart';
import 'package:get/get.dart';
import 'fr_fr.dart';
import 'en_us.dart';
import 'ar_dz.dart';

/// GetX Translations class.
/// Register it in GetMaterialApp:
///
/// ```dart
/// GetMaterialApp(
///   translations: AppTranslations(),
///   locale: const Locale('fr', 'FR'),
///   fallbackLocale: const Locale('fr', 'FR'),
/// )
/// ```
///
/// Then use any key with .tr:
///   Text('dashboard'.tr)
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': {...frFR, ...activityReportFr},
    'en_US': {...enUS, ...activityReportEn},
    'ar_DZ': {...arDZ, ...activityReportAr},
  };
}
