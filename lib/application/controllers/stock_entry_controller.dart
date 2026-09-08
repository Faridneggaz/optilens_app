import 'package:get/get.dart';
import '../../data/repositories/stock_entry_repository.dart';
import '../../domain/response/stock_entry_response.dart';
import '../../core/services/session_service.dart';

class StockEntryController extends GetxController {
  final StockEntryRepository _repo = StockEntryRepository();

  Future<StockEntryResponse?> fetchLastStockEntries({
    int limit  = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) async {
    try {
      final response = await _repo.fetchLastStockEntries(
        token: Get.find<SessionService>().authToken,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );
      return response;
    } catch (_) {
      return null;
    }
  }
}