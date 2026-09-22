import 'package:get/get.dart';

/// Resolves a GetX key, with a locale fallback when the map was not reloaded.
String taskTr(String key, {required String fr, required String en, required String ar}) {
  final translated = key.tr;
  if (translated != key) return translated;
  switch (Get.locale?.languageCode) {
    case 'ar':
      return ar;
    case 'en':
      return en;
    default:
      return fr;
  }
}

String get taskPickEmployee => taskTr(
      'task_pick_employee',
      fr: 'Choisir un employé',
      en: 'Choose an employee',
      ar: 'اختر موظفاً',
    );

String get taskSearchEmployeeHint => taskTr(
      'task_search_employee_hint',
      fr: 'Rechercher un employé...',
      en: 'Search an employee...',
      ar: 'ابحث عن موظف...',
    );

String get taskNoUsersFound => taskTr(
      'task_no_users_found',
      fr: 'Aucun employé trouvé',
      en: 'No employee found',
      ar: 'لم يتم العثور على موظف',
    );
