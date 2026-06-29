import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';

enum WalletType {
  cash,
  bank,
  eWallet,
  investment,
  goal;

  String get apiValue {
    return switch (this) {
      WalletType.eWallet => 'e_wallet',
      _ => name,
    };
  }

  static WalletType fromApiValue(String value) {
    return switch (value) {
      'cash' => WalletType.cash,
      'bank' => WalletType.bank,
      'e_wallet' => WalletType.eWallet,
      'investment' => WalletType.investment,
      'goal' => WalletType.goal,
      _ => throw FormatException('Unknown wallet type "$value".'),
    };
  }
}

/// What a shared-wallet member is allowed to do.
/// - member: read + write (can record transactions)
/// - viewer: read only (can see the wallet, cannot record)
enum WalletInviteRole {
  viewer,
  member;

  String get apiValue => name;
}

enum WalletShareStatus {
  pending,
  joined,
  rejected;

  String get apiValue => name;

  static WalletShareStatus fromApiValue(String value) {
    return switch (value) {
      'pending' => WalletShareStatus.pending,
      'joined' => WalletShareStatus.joined,
      'rejected' => WalletShareStatus.rejected,
      _ => throw FormatException('Unknown wallet share status "$value".'),
    };
  }
}

class WalletMember {
  const WalletMember({
    required this.walletId,
    required this.userId,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletMember.fromJson(JsonMap json) {
    return WalletMember(
      walletId: ApiJson.readString(json, 'wallet_id'),
      userId: ApiJson.readString(json, 'user_id'),
      email: ApiJson.readString(json, 'email'),
      role: ApiJson.readString(json, 'role'),
      status: WalletShareStatus.fromApiValue(
        ApiJson.readString(json, 'status'),
      ),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String walletId;
  final String userId;
  final String email;
  final String role;
  final WalletShareStatus status;
  final String createdAt;
  final String updatedAt;
}

class Wallet {
  const Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.balanceMinor,
    required this.color,
    this.icon = '',
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.goalId,
    this.role,
    this.shareStatus,
    this.members = const [],
  });

  factory Wallet.fromJson(JsonMap json) {
    final memberMaps = ApiJson.readObjectList({
      'members': json['members'] ?? const [],
    }, 'members');
    return Wallet(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      name: ApiJson.readString(json, 'name'),
      type: WalletType.fromApiValue(ApiJson.readString(json, 'type')),
      currencyCode: ApiJson.readString(json, 'currency_code'),
      balanceMinor: ApiJson.readInt(json, 'balance_minor'),
      color: ApiJson.optionalString(json, 'color'),
      icon: ApiJson.optionalString(json, 'icon'),
      description: ApiJson.optionalString(json, 'description'),
      goalId: ApiJson.nullableString(json, 'goal_id'),
      role: ApiJson.nullableString(json, 'role'),
      shareStatus: _shareStatus(json),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
      members: memberMaps.map(WalletMember.fromJson).toList(growable: false),
    );
  }

  static WalletShareStatus? _shareStatus(JsonMap json) {
    final value = ApiJson.nullableString(json, 'share_status');
    return value == null ? null : WalletShareStatus.fromApiValue(value);
  }

  final String id;
  final String userId;
  final String name;
  final WalletType type;
  final String currencyCode;
  final int balanceMinor;
  final String color;
  final String icon;
  final String description;
  final String? goalId;
  final String? role;
  final WalletShareStatus? shareStatus;
  final String createdAt;
  final String updatedAt;
  final List<WalletMember> members;

  bool get isGoal => type == WalletType.goal;

  /// True when the current user only has read-only (viewer) access to this
  /// shared wallet. Owners and read/write members have role 'owner'/'member'
  /// (or null for a private owned wallet).
  bool get isViewer => role == 'viewer';

  /// Whether the current user may record/edit transactions in this wallet.
  bool get canWrite => !isViewer;
}

class WalletListResponse {
  const WalletListResponse({required this.wallets, required this.pagination});

  factory WalletListResponse.fromJson(JsonMap json) {
    return WalletListResponse(
      wallets: ApiJson.readObjectList(
        json,
        'wallets',
      ).map(Wallet.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<Wallet> wallets;
  final Pagination pagination;
}

class WalletMembersResponse {
  const WalletMembersResponse({required this.members});

  factory WalletMembersResponse.fromJson(JsonMap json) {
    return WalletMembersResponse(
      members: ApiJson.readObjectList(
        json,
        'members',
      ).map(WalletMember.fromJson).toList(growable: false),
    );
  }

  final List<WalletMember> members;
}

class WalletAnalytics {
  const WalletAnalytics({
    required this.walletId,
    required this.month,
    required this.inflowMinor,
    required this.outflowMinor,
    required this.transactionCount,
    this.lastActivityAt,
  });

  factory WalletAnalytics.fromJson(JsonMap json) {
    return WalletAnalytics(
      walletId: ApiJson.readString(json, 'wallet_id'),
      month: ApiJson.readString(json, 'month'),
      inflowMinor: ApiJson.readInt(json, 'inflow_minor'),
      outflowMinor: ApiJson.readInt(json, 'outflow_minor'),
      transactionCount: ApiJson.readInt(json, 'transaction_count'),
      lastActivityAt: ApiJson.nullableString(json, 'last_activity_at'),
    );
  }

  final String walletId;
  final String month;
  final int inflowMinor;
  final int outflowMinor;
  final int transactionCount;
  final String? lastActivityAt;
}

class WalletRequest {
  const WalletRequest({
    required this.name,
    required this.type,
    required this.currencyCode,
    this.balanceMinor,
    this.color,
    this.icon,
    this.description,
  });

  final String name;
  final WalletType type;
  final String currencyCode;
  final int? balanceMinor;
  final String? color;
  final String? icon;
  final String? description;

  JsonMap toCreateJson() => {
    'name': name,
    'type': type.apiValue,
    'currency_code': currencyCode,
    'balance_minor': balanceMinor ?? 0,
    if (color != null) 'color': color,
    if (icon != null) 'icon': icon,
    if (description != null) 'description': description,
  };

  JsonMap toUpdateJson() => {
    'name': name,
    'type': type.apiValue,
    'currency_code': currencyCode,
    if (color != null) 'color': color,
    if (icon != null) 'icon': icon,
    if (description != null) 'description': description,
  };
}

class WalletInviteRequest {
  const WalletInviteRequest({
    required this.email,
    this.role = WalletInviteRole.member,
  });

  final String email;
  final WalletInviteRole role;

  JsonMap toJson() => {'email': email, 'role': role.apiValue};
}

class WalletInviteResponse {
  const WalletInviteResponse({required this.status});

  factory WalletInviteResponse.fromJson(JsonMap json) {
    return WalletInviteResponse(
      status: WalletShareStatus.fromApiValue(
        ApiJson.readString(json, 'status'),
      ),
    );
  }

  final WalletShareStatus status;

  JsonMap toJson() => {'status': status.apiValue};
}
