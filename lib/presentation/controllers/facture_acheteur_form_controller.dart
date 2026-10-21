import 'package:get/get.dart';

import '../../core/services/session_service.dart';
import '../../domain/entities/manque.dart';
import '../../domain/failures/failures.dart';
import '../../domain/results/action_result.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';
import '../../utils/manque_status_helper.dart';
import 'facture_acheteur_controller.dart';

class FactureAcheteurFormController extends GetxController {
  FactureAcheteurFormController({ManqueUseCases? manque, String? name})
      : _manque = manque ?? Get.find<ManqueUseCases>(),
        _name = name ?? '';

  final ManqueUseCases _manque;
  String _name;

  final facture = Rxn<FactureAcheteur>();
  final lineItems = <FactureAcheteurItem>[].obs;
  final modeAchat = modeAchatPoche.obs;
  final supplier = ''.obs;
  final supplierName = ''.obs;
  final suppliers = <SupplierOption>[].obs;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final isSubmitting = false.obs;
  final isPaying = false.obs;

  String get _token => Get.find<SessionService>().authToken;

  double get liveTotal =>
      lineItems.fold(0.0, (sum, e) => sum + e.amount);

  bool get canSubmit {
    if (facture.value == null || !facture.value!.isDraft) return false;
    final checked = lineItems.where((e) => e.willBuy).toList();
    if (checked.isEmpty) return false;
    if (checked.any((e) => e.rate <= 0)) return false;
    if (modeAchat.value == modeAchatCredit && supplier.value.trim().isEmpty) {
      return false;
    }
    return true;
  }

  bool get isReadOnly {
    final f = facture.value;
    if (f == null) return true;
    return !f.isDraft;
  }

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
      final f = await _manque.fetchFactureDetail(token: _token, name: _name);
      facture.value = f;
      lineItems.value = f.items
          .map(
            (e) => FactureAcheteurItem(
              itemCode: e.itemCode,
              itemName: e.itemName,
              qty: e.qty,
              uom: e.uom,
              willBuy: e.willBuy,
              rate: e.rate,
            ),
          )
          .toList();
      modeAchat.value =
          f.modeAchat.trim().isEmpty ? modeAchatPoche : f.modeAchat;
      supplier.value = f.supplier;
      supplierName.value = f.supplierName;
      await loadSuppliers();
    } catch (e) {
      if (e is! InvalidSessionException && e is! AccessDeniedException) {
        ErrorFeedback.snackbar(e, fallbackKey: 'manque_failed_load_facture');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSuppliers({String? company, String? search}) async {
    try {
      suppliers.value = await _manque.fetchSuppliers(
        token: _token,
        company: company,
        searchText: search,
      );
    } catch (_) {}
  }

  void setMode(String mode) {
    modeAchat.value = mode;
    if (mode == modeAchatPoche) {
      supplier.value = '';
      supplierName.value = '';
    }
    lineItems.refresh();
  }

  void setSupplier(SupplierOption? s) {
    if (s == null) {
      supplier.value = '';
      supplierName.value = '';
    } else {
      supplier.value = s.name;
      supplierName.value = s.displayName;
    }
  }

  void toggleWillBuy(int index, bool value) {
    if (isReadOnly) return;
    final item = lineItems[index];
    item.willBuy = value;
    if (!value) item.rate = 0;
    lineItems.refresh();
  }

  void setRate(int index, double rate) {
    if (isReadOnly) return;
    lineItems[index].rate = rate < 0 ? 0 : rate;
    lineItems.refresh();
  }

  List<Map<String, dynamic>> _payloadItems() => lineItems
      .map(
        (e) => {
          'item_code': e.itemCode,
          'will_buy': e.willBuy ? 1 : 0,
          'rate': e.rate,
          'qty': e.qty,
        },
      )
      .toList();

  Future<ActionResult> saveDraft() async {
    if (isSaving.value || isReadOnly) return ActionResult.failure('busy');
    isSaving.value = true;
    try {
      final result = await _manque.saveFactureDraft(
        token: _token,
        name: _name,
        modeAchat: modeAchat.value,
        supplier: modeAchat.value == modeAchatCredit ? supplier.value : '',
        items: _payloadItems(),
      );
      if (result.isSuccess) await fetchDetail();
      return result;
    } finally {
      isSaving.value = false;
    }
  }

  Future<ActionResult> submit() async {
    if (isSubmitting.value || !canSubmit) {
      return ActionResult.failure('manque_submit_invalid'.tr);
    }
    isSubmitting.value = true;
    try {
      final result = await _manque.submitFacture(
        token: _token,
        name: _name,
        modeAchat: modeAchat.value,
        supplier: modeAchat.value == modeAchatCredit ? supplier.value : '',
        items: _payloadItems(),
      );
      if (result.isSuccess) {
        await fetchDetail();
        _refreshList();
      }
      return result;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<ActionResult> pay() async {
    if (isPaying.value) return ActionResult.failure('busy');
    final f = facture.value;
    if (f == null || !f.canPay) {
      return ActionResult.failure('manque_cannot_pay'.tr);
    }
    isPaying.value = true;
    try {
      final result = await _manque.payFacture(token: _token, name: _name);
      if (result.isSuccess) {
        await fetchDetail();
        _refreshList();
      }
      return result;
    } finally {
      isPaying.value = false;
    }
  }

  Future<ActionResult> cancel() async {
    final result = await _manque.cancelFacture(token: _token, name: _name);
    if (result.isSuccess) {
      _refreshList();
      Get.back();
    }
    return result;
  }

  void _refreshList() {
    if (Get.isRegistered<FactureAcheteurController>()) {
      Get.find<FactureAcheteurController>().onRefresh();
    }
  }
}
