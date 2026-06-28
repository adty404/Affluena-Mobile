import '../../../core/api/api_json.dart';

enum GoalStatus {
  active,
  achieved,
  cancelled;

  String get apiValue => name;

  String get label => switch (this) {
    GoalStatus.active => 'Aktif',
    GoalStatus.achieved => 'Tercapai',
    GoalStatus.cancelled => 'Dibatalkan',
  };

  static GoalStatus fromApiValue(String value) {
    return switch (value) {
      'active' => GoalStatus.active,
      'achieved' || 'completed' => GoalStatus.achieved,
      'cancelled' => GoalStatus.cancelled,
      _ => throw FormatException('Unknown goal status "$value".'),
    };
  }
}

enum GoalMemberStatus {
  pending,
  joined,
  rejected;

  String get apiValue => name;

  String get label => switch (this) {
    GoalMemberStatus.pending => 'Menunggu',
    GoalMemberStatus.joined => 'Bergabung',
    GoalMemberStatus.rejected => 'Ditolak',
  };

  static GoalMemberStatus fromApiValue(String value) {
    return switch (value) {
      'pending' => GoalMemberStatus.pending,
      'joined' => GoalMemberStatus.joined,
      'rejected' => GoalMemberStatus.rejected,
      _ => throw FormatException('Unknown goal member status "$value".'),
    };
  }
}

class GoalMember {
  const GoalMember({
    required this.goalId,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalMember.fromJson(JsonMap json) {
    return GoalMember(
      goalId: ApiJson.readString(json, 'goal_id'),
      userId: ApiJson.readString(json, 'user_id'),
      status: GoalMemberStatus.fromApiValue(ApiJson.readString(json, 'status')),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String goalId;
  final String userId;
  final GoalMemberStatus status;
  final String createdAt;
  final String updatedAt;

  /// The best identity we can show for this member. The goal-member API only
  /// returns the raw user id (no name/email), so we surface a short, stable
  /// reference derived from that id rather than inventing a display name.
  String get identityLabel {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return 'Anggota';
    final head = trimmed.length <= 8 ? trimmed : trimmed.substring(0, 8);
    return 'Anggota $head';
  }
}

class Goal {
  const Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmountMinor,
    required this.collectedAmountMinor,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.members = const [],
  });

  factory Goal.fromJson(JsonMap json) {
    return Goal(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      name: ApiJson.readString(json, 'name'),
      targetAmountMinor: ApiJson.readInt(json, 'target_amount_minor'),
      collectedAmountMinor: ApiJson.readInt(json, 'collected_amount_minor'),
      deadline: ApiJson.nullableString(json, 'deadline'),
      status: GoalStatus.fromApiValue(ApiJson.readString(json, 'status')),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
      members: ApiJson.readObjectList(
        json,
        'members',
      ).map(GoalMember.fromJson).toList(growable: false),
    );
  }

  final String id;
  final String userId;
  final String name;
  final int targetAmountMinor;
  final int collectedAmountMinor;
  final String? deadline;
  final GoalStatus status;
  final String createdAt;
  final String updatedAt;
  final List<GoalMember> members;

  int get progressPercent {
    if (targetAmountMinor <= 0) return 0;
    return (collectedAmountMinor / targetAmountMinor * 100)
        .clamp(0, 100)
        .round();
  }

  bool get isActive => status == GoalStatus.active;

  Goal copyForRequest({
    required String id,
    required String name,
    required int targetAmountMinor,
    required String deadline,
  }) {
    return Goal(
      id: id,
      userId: userId,
      name: name,
      targetAmountMinor: targetAmountMinor,
      collectedAmountMinor: collectedAmountMinor,
      deadline: deadline,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      members: members,
    );
  }
}

class GoalListResponse {
  const GoalListResponse({required this.goals});

  factory GoalListResponse.fromJson(Object? data) {
    if (data is! List) {
      throw const FormatException('Expected goals response to be a list.');
    }
    return GoalListResponse(
      goals: data
          .map((item) {
            if (item is Map<String, Object?>) return Goal.fromJson(item);
            if (item is Map) {
              return Goal.fromJson(Map<String, Object?>.from(item));
            }
            throw const FormatException('Expected goal item to be an object.');
          })
          .toList(growable: false),
    );
  }

  final List<Goal> goals;
}

class GoalRequest {
  const GoalRequest({
    required this.name,
    required this.targetAmountMinor,
    required this.deadline,
  });

  final String name;
  final int targetAmountMinor;
  final String deadline;

  JsonMap toJson() => {
    'name': name,
    'target_amount_minor': targetAmountMinor,
    'deadline': deadline,
  };
}

/// Payload for an active -> achieved/cancelled transition. Re-sends the goal's
/// existing editable fields (the only update endpoint the API exposes) plus the
/// target status so the request is forward-compatible the moment the backend
/// honors a status field on update.
class GoalStatusRequest {
  const GoalStatusRequest({
    required this.name,
    required this.targetAmountMinor,
    required this.deadline,
    required this.status,
  });

  final String name;
  final int targetAmountMinor;
  final String deadline;
  final GoalStatus status;

  JsonMap toJson() => {
    'name': name,
    'target_amount_minor': targetAmountMinor,
    'deadline': deadline,
    'status': status.apiValue,
  };
}

class GoalInviteRequest {
  const GoalInviteRequest({required this.email});

  final String email;

  JsonMap toJson() => {'email': email};
}

class GoalInviteResponseRequest {
  const GoalInviteResponseRequest({required this.status});

  final GoalMemberStatus status;

  JsonMap toJson() => {'status': status.apiValue};
}
