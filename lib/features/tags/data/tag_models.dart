import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';

class Tag {
  const Tag({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tag.fromJson(JsonMap json) {
    return Tag(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      name: ApiJson.readString(json, 'name'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String createdAt;
  final String updatedAt;
}

class TagListResponse {
  const TagListResponse({required this.tags, required this.pagination});

  factory TagListResponse.fromJson(JsonMap json) {
    return TagListResponse(
      tags: ApiJson.readObjectList(
        json,
        'tags',
      ).map(Tag.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<Tag> tags;
  final Pagination pagination;
}

class TagRequest {
  const TagRequest({required this.name});

  final String name;

  JsonMap toJson() => {'name': name};
}
