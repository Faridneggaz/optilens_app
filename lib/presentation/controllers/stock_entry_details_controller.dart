import 'package:get/get.dart';
import '../../domain/entities/stock_entry_details_response.dart';
import '../../domain/entities/stock_entry_item.dart' as model;
import '../../domain/usecases/usecases.dart';
import '../../core/services/session_service.dart';
import '../../domain/results/action_result.dart';
import '../../domain/failures/failures.dart';
import '../../utils/error_feedback.dart';

class StockEntryDetailsController extends GetxController {
  StockEntryDetailsController({StockEntryUseCases? stock})
      : _stock = stock ?? Get.find<StockEntryUseCases>();

  final StockEntryUseCases _stock;

  final data            = Rxn<StockEntryDetailsResponse>();
  final isLoading       = true.obs;
  final isSubmitting    = false.obs;

  final fromWarehouseValidated  = false.obs;
  final toWarehouseValidated    = false.obs;
  final validatedItemIndices    = <int>{}.obs;

  String _name  = '';

  @override
  void onInit() {
    super.onInit();
    final data = Get.arguments;
    if (data != null && data is Map<String, dynamic>) {
      _name  = data['name']  as String? ?? '';
    }
    fetchDetails();
  }

  bool get isUnapproved {
    if (data.value == null) return false;
    final s = data.value!.stockEntry.status.toLowerCase().trim();
    if (s.isEmpty) return true;
    const done = {
      'approved',
      'rejected',
      'cancelled',
      'canceled',
    };
    return !done.contains(s);
  }

  bool get isPending => isUnapproved;

  bool get canApprove => isUnapproved;

  Future<void> fetchDetails() async {
    isLoading.value = true;
    try {
      final response = await _stock.fetchDetails(
          name: _name, 
          token: Get.find<SessionService>().authToken);
      data.value = response;
      if (!isPending && data.value != null) {
        fromWarehouseValidated.value = true;
        toWarehouseValidated.value   = true;
        validatedItemIndices
          ..clear()
          ..addAll(Set.from(List.generate(data.value!.items.length, (i) => i)));
      }
    } catch (e) {
      ErrorFeedback.snackbar(
        e,
        fallbackKey: 'failed_load_stock',
      );
      if (e is RepositoryException && e.message.isNotEmpty) {
        // Keep last good data if refresh fails; only clear on first load.
        if (data.value == null) {
          data.value = null;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    await fetchDetails();
  }

  void toggleItemValidation(int index) {
    final updated = Set<int>.from(validatedItemIndices);
    if (updated.contains(index)) {
      updated.remove(index);
    } else {
      updated.add(index);
    }
    validatedItemIndices
      ..clear()
      ..addAll(updated);
  }

  void removeItem(int index) {
    data.value!.items.removeAt(index);
    final updated = validatedItemIndices
        .where((i) => i != index)
        .map((i) => i > index ? i - 1 : i)
        .toSet();
    validatedItemIndices
      ..clear()
      ..addAll(updated);
    data.refresh();
  }

  void addItem(model.StockEntryItem item) {
    data.value!.items.add(item);
    data.refresh();
  }

  Future<ActionResult> approveStockEntry() async {
    isSubmitting.value = true;
    try {
      final itemsToSend = data.value!.items
          .map((e) => {
                'item_code': e.itemCode,
                'itemName': e.itemCode,
                'item_name': e.itemName,
                'quantity': e.quantity,
                'qty': e.quantity,
                'fromWarehouse': e.fromWarehouse,
                'from_warehouse': e.fromWarehouse,
                'toWarehouse': e.toWarehouse,
                'to_warehouse': e.toWarehouse,
              })
          .toList();

      final res = await _stock.approveStockEntry(
        name: _name,
        token: Get.find<SessionService>().authToken,
        items: itemsToSend,
        action: 'approve',
      );
      if (res.isSuccess) {
        data.value?.stockEntry.status = 'Approved';
        data.refresh();
      }
      return res;
    } catch (e) {
      return ActionResult.fromException(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<List<Map<String, String>>> searchItems(String searchText) async {
    try {
      return await _stock.searchItems(
        token: Get.find<SessionService>().authToken,
        searchText: searchText,
      );
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'no_item_found');
      return [];
    }
  }
}