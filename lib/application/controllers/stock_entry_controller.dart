import 'package:get/get.dart';
import '../../data/repositories/stock_entry_repository.dart';
import '../../domain/response/stock_entry_response.dart';

class StockEntryController extends GetxController {
  final StockEntryRepository _repo = StockEntryRepository();

  Future<StockEntryResponse?> fetchLastStockEntries({
    required String token,
    int limit  = 20,
    int offset = 0,
  }) async {
    try {
      return await _repo.fetchLastStockEntries(
          token: token, limit: limit, offset: offset);
    } catch (_) {
      return null;
    }
  }
}