import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'insight_models.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return DioInsightsRepository(ref.watch(dioProvider));
});

abstract interface class InsightsRepository {
  Future<ReportResponse> getReport({required ReportKind kind, String? month});

  Future<CsvExportResult> exportCsv(ExportCsvRequest request);

  Future<ExportJobsResponse> listExportJobs({int? limit, int? offset});

  Future<ExportJob> getExportJob(String id);

  Future<ActivityListResponse> listActivities({
    int? limit,
    int? offset,
    String? sort,
  });

  Future<ActivityItem> getActivity(String id);

  Future<AlertsResponse> listAlerts({String? month});

  Future<InsightAlert> getAlert(String id);

  Future<NotificationRulesResponse> listNotificationRules();

  Future<NotificationRule> updateNotificationRule(
    String id,
    NotificationRuleUpdate update,
  );
}

class DioInsightsRepository implements InsightsRepository {
  const DioInsightsRepository(this._dio);

  final Dio _dio;

  @override
  Future<ReportResponse> getReport({
    required ReportKind kind,
    String? month,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/reports/${kind.apiValue}',
      queryParameters: _query({'month': month}),
    );
    return ReportResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<CsvExportResult> exportCsv(ExportCsvRequest request) async {
    final response = await _dio.get<List<int>>(
      '/export/csv',
      queryParameters: request.toQuery(),
      options: Options(responseType: ResponseType.bytes),
    );
    return CsvExportResult(
      bytes: response.data ?? const [],
      filename: _filenameFromDisposition(
        response.headers.value('content-disposition'),
      ),
    );
  }

  @override
  Future<ExportJobsResponse> listExportJobs({int? limit, int? offset}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/export/jobs',
      queryParameters: _query({'limit': limit, 'offset': offset}),
    );
    return ExportJobsResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<ExportJob> getExportJob(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/export/jobs/$id');
    return ExportJob.fromJson(_responseMap(response.data));
  }

  @override
  Future<ActivityListResponse> listActivities({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/activities',
      queryParameters: _query({'limit': limit, 'offset': offset, 'sort': sort}),
    );
    return ActivityListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<ActivityItem> getActivity(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/activities/$id');
    return ActivityItem.fromJson(_responseMap(response.data));
  }

  @override
  Future<AlertsResponse> listAlerts({String? month}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/alerts',
      queryParameters: _query({'month': month}),
    );
    return AlertsResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<InsightAlert> getAlert(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/alerts/$id');
    return InsightAlert.fromJson(_responseMap(response.data));
  }

  @override
  Future<NotificationRulesResponse> listNotificationRules() async {
    final response = await _dio.get<Map<String, Object?>>(
      '/notifications/rules',
    );
    return NotificationRulesResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<NotificationRule> updateNotificationRule(
    String id,
    NotificationRuleUpdate update,
  ) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/notifications/rules/$id',
      data: update.toJson(),
    );
    return NotificationRule.fromJson(_responseMap(response.data));
  }
}

Map<String, Object?> _query(Map<String, Object?> values) {
  return Map<String, Object?>.from(values)
    ..removeWhere((key, value) => value == null || value == '');
}

JsonMap _responseMap(Object? data) {
  if (data is Map<String, Object?>) return data;
  if (data is Map) return Map<String, Object?>.from(data);
  throw const FormatException('Expected response body to be an object.');
}

String _filenameFromDisposition(String? value) {
  if (value == null || value.isEmpty) return 'transactions_export.csv';
  final match = RegExp('filename="?([^";]+)"?').firstMatch(value);
  return match?.group(1) ?? 'transactions_export.csv';
}
