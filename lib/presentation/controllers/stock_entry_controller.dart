import 'package:get/get.dart';
import '../../domain/entities/stock_entry_response.dart';
import '../../domain/usecases/usecases.dart';
import '../../core/services/session_service.dart';
import '../../utils/error_feedback.dart';

class StockEntryController extends GetxController {
  StockEntryController({StockEntryUseCases? stock})
      : _stock = stock ?? Get.find<StockEntryUseCases>();

  final StockEntryUseCases _stock;

  Future<StockEntryResponse?> fetchLastStockEntries({
    int limit  = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) async {
    try {
      final response = await _stock.fetchLastStockEntries(
        token: Get.find<SessionService>().authToken,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );
      return response;
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'failed_load_stock');
      return null;
    }
  }
}