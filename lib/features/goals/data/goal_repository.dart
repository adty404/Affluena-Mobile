import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'goal_models.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return DioGoalRepository(ref.watch(dioProvider));
});

abstract interface class GoalRepository {
  Future<GoalListResponse> listGoals();

  Future<Goal> getGoal(String id);

  Future<Goal> createGoal(GoalRequest request);

  Future<Goal> updateGoal(String id, GoalRequest request);

  Future<void> inviteMember(String id, GoalInviteRequest request);

  Future<void> respondInvite(
    String id,
    String userId,
    GoalInviteResponseRequest request,
  );
}

class DioGoalRepository implements GoalRepository {
  const DioGoalRepository(this._dio);

  final Dio _dio;

  @override
  Future<GoalListResponse> listGoals() async {
    final response = await _dio.get<List<Object?>>('/goals');
    return GoalListResponse.fromJson(response.data);
  }

  @override
  Future<Goal> getGoal(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/goals/$id');
    return Goal.fromJson(_responseMap(response.data));
  }

  @override
  Future<Goal> createGoal(GoalRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/goals',
      data: request.toJson(),
    );
    return Goal.fromJson(_responseMap(response.data));
  }

  @override
  Future<Goal> updateGoal(String id, GoalRequest request) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/goals/$id',
      data: request.toJson(),
    );
    return Goal.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> inviteMember(String id, GoalInviteRequest request) async {
    await _dio.post<Map<String, Object?>>(
      '/goals/$id/members',
      data: request.toJson(),
    );
  }

  @override
  Future<void> respondInvite(
    String id,
    String userId,
    GoalInviteResponseRequest request,
  ) async {
    await _dio.put<Map<String, Object?>>(
      '/goals/$id/members/$userId/respond',
      data: request.toJson(),
    );
  }
}

JsonMap _responseMap(Object? data) {
  if (data is Map<String, Object?>) return data;
  if (data is Map) return Map<String, Object?>.from(data);
  throw const FormatException('Expected response body to be an object.');
}
