import 'api_json.dart';

class Pagination {
  const Pagination({
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory Pagination.fromJson(JsonMap json) {
    return Pagination(
      total: ApiJson.readInt(json, 'total'),
      limit: ApiJson.readInt(json, 'limit'),
      offset: ApiJson.readInt(json, 'offset'),
    );
  }

  final int total;
  final int limit;
  final int offset;

  bool get hasMore => offset + limit < total;
}
