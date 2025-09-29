import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/models/item_dto.dart';
import '../models/match_dto.dart';
import '../models/flag_dto.dart';

class ItemApi {
  ItemApi._();

  static final ItemApi I = ItemApi._();

  final ApiClient _client = ApiClient.I;

  Future<List<ItemDto>> listItems() async {
    final json = await _client.get('/items/');
    if (json is List) {
      return json.map((e) => ItemDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }
    return const <ItemDto>[];
  }

  Future<ItemDto> createItem({
    required String title,
    String? description,
    required String status,
    double? lat,
    double? lng,
  }) async {
    final response = await _client.post(
      '/items/',
      data: {
        'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
        'status': status,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    return ItemDto.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<List<MatchDto>> listMatches(int itemId) async {
    final response = await _client.get('/matches/$itemId');
    if (response is List) {
      return response
          .map((e) => MatchDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const <MatchDto>[];
  }

  Future<ItemDto> updateItemStatus(int itemId, String status) async {
    final response = await _client.patch(
      '/items/$itemId',
      data: {'status': status},
    );
    if (response is Map) {
      return ItemDto.fromJson(Map<String, dynamic>.from(response));
    }
    throw ApiException(500, 'Unexpected response when updating status');
  }

  Future<FlagDto> flagItem({required int itemId, required String reason}) async {
    final response = await _client.post(
      '/items/$itemId/flags',
      data: {
        'reason': reason,
        'source': 'user',
      },
    );
    if (response is Map) {
      return FlagDto.fromJson(Map<String, dynamic>.from(response));
    }
    throw ApiException(500, 'Unexpected response when flagging item');
  }
}
