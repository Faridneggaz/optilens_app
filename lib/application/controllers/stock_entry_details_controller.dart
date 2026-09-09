import 'package:get/get.dart';
import '../../data/repositories/stock_entry_details_repository.dart';
import '../../data/repositories/employee_api.dart';
import '../../domain/response/stock_entry_details_response.dart';
import '../../domain/response/stock_entry_item.dart' as model;
import '../../core/services/session_service.dart';
import '../../utils/error_feedback.dart';

class StockEntryDetailsController extends GetxController {
  StockEntryDetailsController({StockEntryDetailsRepository? repo})
      : _repo = repo ?? Get.find<StockEntryDetailsRepository>();

  final StockEntryDetailsRepository _repo;

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

  bool get isPending {
    if (data.value == null) return false;
    final s = data.value!.stockEntry.status.toLowerCase();
    return s == 'pending' || s == 'draft';
  }

  bool get canApprove {
    if (!isPending) return false;
    final itemsReady = data.value != null &&
        validatedItemIndices.length == data.value!.items.length;
    bool warehousesReady = true;
    if (data.value?.stockEntry.fromWarehouse.isNotEmpty ?? false) {
      warehousesReady = warehousesReady && fromWarehouseValidated.value;
    }
    if (data.value?.stockEntry.toWarehouse.isNotEmpty ?? false) {
      warehousesReady = warehousesReady && toWarehouseValidated.value;
    }
    return itemsReady && warehousesReady;
  }

  Future<void> fetchDetails() async {
    isLoading.value = true;
    try {
      final response = await _repo.fetchDetails(
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
      ErrorFeedback.snackbar(e, fallbackKey: 'failed_load_stock');
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

  Future<Map<String, dynamic>> approveStockEntry() async {
    isSubmitting.value = true;
    try {
      final itemsToSend = data.value!.items.map((e) => {
            'itemName':      e.itemCode,
            'quantity':      e.quantity,
            'fromWarehouse': e.fromWarehouse,
            'toWarehouse':   e.toWarehouse,
          }).toList();

      return await _repo.approveStockEntry(
        name:   _name,
        token:  Get.find<SessionService>().authToken,
        items:  itemsToSend,
        action: 'approve',
      );
    } catch (e) {
      return EmployeeApi.failureResult(e);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<List<Map<String, String>>> searchItems(String searchText) async {
    try {
      return await _repo.searchItems(token: Get.find<SessionService>().authToken, searchText: searchText);
    } catch (_) {
      return [];
    }
  }
}