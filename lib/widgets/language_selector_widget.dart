import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../application/controllers/language_controller.dart';

// ── Point d'entrée public ─────────────────────────────────────────────────────

class LanguageSelectorWidget {
  LanguageSelectorWidget._();

  static void show() {
    Get.bottomSheet(
      _LanguageBottomSheet(), // PAS de const — instance fraîche à chaque appel
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _LanguageBottomSheet extends StatelessWidget {
  // PAS de const constructeur (Rule 3)
  // ignore: prefer_const_constructors_in_immutables
  _LanguageBottomSheet();

  @override
  Widget build(BuildContext context) {
    final lc = Get.find<LanguageController>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de glissement
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Titre (Rule 4)
          const Text(
            'Langue / Language / اللغة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Liste des langues — Obx rend la coche réactive (Rule 1)
          Obx(() => Column(
            children: LanguageController.available.map((lang) {
              final isSelected =
                  lc.current.value.translationKey == lang.translationKey;
              return ListTile(
                leading: Text(lang.flag,
                    style: const TextStyle(fontSize: 24)),
                title: Text(
                  lang.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.teal
                        : const Color(0xFF1F2837),
                  ),
                ),
                // Rule 5 — coche teal si langue active
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.teal)
                    : null,
                tileColor: isSelected
                    ? Colors.teal.withValues(alpha: 0.08)
                    : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                // Rule 2 — changeLanguage + Get.back()
                onTap: () {
                  lc.changeLanguage(lang);
                  Get.back();
                },
              );
            }).toList(),
          )),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Bouton compact pour AppBar ────────────────────────────────────────────────

/// ```dart
/// actions: [const LanguageSelectorButton()],
/// ```
class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final lc = Get.find<LanguageController>();
    return Obx(
      () => GestureDetector(
        onTap: LanguageSelectorWidget.show,
        child: Container(
          margin:  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00A69C).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lc.current.value.flag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more,
                  color: Color(0xFF00A69C), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
