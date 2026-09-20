// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/stock_entry_details_response.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/stock_entry_details_repository.dart';
import '../mappers/json_mappers.dart';

class StockEntryDetailsRepositoryImpl implements StockEntryDetailsRepository {
  StockEntryDetailsRepositoryImpl(this._client);

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
    return StockEntryDetailsResponseMapper.fromJson(decoded);
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
    if (resData is String) {
      final text = resData.trim();
      final lower = text.toLowerCase();
      if (lower.contains('success') ||
          lower.contains('approved') ||
          lower.contains(action.toLowerCase())) {
        return {'message': 'Success', 'detail': text};
      }
      throw RepositoryException(text.isEmpty ? 'Operation failed' : text);
    }
    if (resData is Map) {
      final map = Map<String, dynamic>.from(resData);
      final nested = map['message'];
      final err = map['error']?.toString();
      final ok = map['message'] == 'Success' ||
          map['success'] == true ||
          map['success'] == 1 ||
          map['status'] == 'success' ||
          (nested is String &&
              (nested.toLowerCase().contains('success') ||
                  nested.toLowerCase().contains('approved'))) ||
          (nested is Map &&
              (nested['success'] == true || nested['message'] == 'Success'));
      if (err != null && err.isNotEmpty && err != 'null' && !ok) {
        throw RepositoryException(err);
      }
      if (ok) {
        return {
          'message': 'Success',
          'detail': map['detail'] ??
              (nested is String ? nested : null) ??
              'Operation completed successfully',
        };
      }
      if (nested is String && nested.trim().isNotEmpty) {
        throw RepositoryException(nested);
      }
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
