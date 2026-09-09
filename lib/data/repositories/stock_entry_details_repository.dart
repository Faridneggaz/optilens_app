import '../../core/network/api_client.dart';
import '../../domain/response/stock_entry_details_response.dart';
import 'repository_exception.dart';

class StockEntryDetailsRepository {
  StockEntryDetailsRepository(this._client);

  final ApiClient _client;

  Future<StockEntryDetailsResponse> fetchDetails({
    required String name,
    required String token,
  }) async {
    final decoded = await _client.getMobile(
      'get_stock_entry_details_by_name',
      query: {'name': name, 'token': token},
      attachToken: false,
    );
    _client.unwrap(decoded);
    return StockEntryDetailsResponse.fromJson(decoded);
  }

  Future<Map<String, dynamic>> approveStockEntry({
    required String name,
    required String token,
    required List<Map<String, dynamic>> items,
    required String action,
  }) async {
    final data = await _client.postMobile(
      'manage_stock_entry',
      query: {'token': token},
      body: {
        'name': name,
        'items': items,
        'action': action,
        'token': token,
      },
      attachToken: false,
    );
    final resData = _client.unwrap(data);
    if (resData is Map && resData['message'] == 'Success') {
      return {
        'message': 'Success',
        'detail': resData['detail'] ?? 'Operation completed successfully',
      };
    }
    throw const RepositoryException('Unknown response format');
  }

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  }) async {
    final decoded = await _client.getMobile(
      'search_items',
      query: {'token': token, 'search_text': searchText},
      attachToken: false,
    );
    final message = _client.unwrap(decoded);
    List itemsList;
    if (message is List) {
      itemsList = message;
    } else if (message is Map && message['message'] is List) {
      itemsList = message['message'] as List;
    } else {
      return [];
    }
    return itemsList
        .map<Map<String, String>>((e) => {
              'item_code': e['item_code']?.toString() ?? '',
              'item_name': e['item_name']?.toString() ?? '',
            })
        .toList();
  }
}
