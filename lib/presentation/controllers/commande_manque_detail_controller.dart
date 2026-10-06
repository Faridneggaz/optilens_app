import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/manque.dart';
import '../../domain/failures/failures.dart';
import '../../domain/results/action_result.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';
import 'commande_manque_controller.dart';

class CommandeManqueDetailController extends GetxController {
  CommandeManqueDetailController({ManqueUseCases? manque, String? name})
      : _manque = manque ?? Get.find<ManqueUseCases>(),
        _name = name ?? '';

  final ManqueUseCases _manque;
  String _name;

  final commande = Rxn<CommandeDeManque>();
  final isLoading = true.obs;
  final isBusy = false.obs;

  String get _token => Get.find<SessionService>().authToken;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      _name = args['name']?.toString() ?? _name;
    } else if (args is String && args.isNotEmpty) {
      _name = args;
    }
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    if (_name.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      commande.value =
          await _manque.fetchCommandeDetail(token: _token, name: _name);
    } catch (e) {
      if (e is! InvalidSessionException && e is! AccessDeniedException) {
        ErrorFeedback.snackbar(e, fallbackKey: 'manque_failed_load_detail');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<ActionResult> envoyer() async {
    if (isBusy.value) return ActionResult.failure('busy');
    isBusy.value = true;
    try {
      final result = await _manque.manageCommande(
        token: _token,
        name: _name,
        action: 'envoyer',
      );
      if (result.isSuccess) {
        await fetchDetail();
        _refreshList();
      }
      return result;
    } finally {
      isBusy.value = false;
    }
  }

  Future<ActionResult> annuler() async {
    if (isBusy.value) return ActionResult.failure('busy');
    isBusy.value = true;
    try {
      final result = await _manque.manageCommande(
        token: _token,
        name: _name,
        action: 'annuler',
      );
      if (result.isSuccess) {
        await fetchDetail();
        _refreshList();
      }
      return result;
    } finally {
      isBusy.value = false;
    }
  }

  Future<ActionResult> openOrCreateFacture() async {
    if (isBusy.value) return ActionResult.failure('busy');
    final cmd = commande.value;
    if (cmd == null) return ActionResult.failure('error_occurred'.tr);

    if (cmd.factureAcheteur.trim().isNotEmpty) {
      Get.toNamed(
        AppRoutes.factureAcheteurForm,
        arguments: {'name': cmd.factureAcheteur},
      );
      return ActionResult.ok(documentName: cmd.factureAcheteur);
    }

    isBusy.value = true;
    try {
      final result = await _manque.createFacture(
        token: _token,
        commandeDeManque: cmd.name,
      );
      if (result.isSuccess &&
          result.documentName != null &&
          result.documentName!.isNotEmpty) {
        await fetchDetail();
        Get.toNamed(
          AppRoutes.factureAcheteurForm,
          arguments: {'name': result.documentName},
        );
      }
      return result;
    } finally {
      isBusy.value = false;
    }
  }

  void _refreshList() {
    if (Get.isRegistered<CommandeManqueController>()) {
      Get.find<CommandeManqueController>().onRefresh();
    }
  }
}
