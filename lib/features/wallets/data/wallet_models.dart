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

enum WalletShareStatus {
  pending,
  joined,
  rejected;

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
  final String description;
  final String? goalId;
  final String? role;
  final WalletShareStatus? shareStatus;
  final String createdAt;
  final String updatedAt;
  final List<WalletMember> members;

  bool get isGoal => type == WalletType.goal;
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

class WalletRequest {
  const WalletRequest({
    required this.name,
    required this.type,
    required this.currencyCode,
    this.balanceMinor,
    this.color,
    this.description,
  });

  final String name;
  final WalletType type;
  final String currencyCode;
  final int? balanceMinor;
  final String? color;
  final String? description;

  JsonMap toCreateJson() => {
    'name': name,
    'type': type.apiValue,
    'currency_code': currencyCode,
    'balance_minor': balanceMinor ?? 0,
    if (color != null) 'color': color,
    if (description != null) 'description': description,
  };

  JsonMap toUpdateJson() => {
    'name': name,
    'type': type.apiValue,
    'currency_code': currencyCode,
    if (color != null) 'color': color,
    if (description != null) 'description': description,
  };
}
