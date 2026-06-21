import '../../../core/api/api_json.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AuthUser.fromJson(JsonMap json) {
    return AuthUser(
      id: ApiJson.readString(json, 'id'),
      email: ApiJson.readString(json, 'email'),
      name: ApiJson.optionalString(json, 'name'),
      avatarUrl: ApiJson.optionalString(json, 'avatar_url'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final String createdAt;
  final String updatedAt;
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  factory AuthTokens.fromJson(JsonMap json) {
    return AuthTokens(
      accessToken: ApiJson.readString(json, 'access_token'),
      refreshToken: ApiJson.readString(json, 'refresh_token'),
      accessTokenExpiresAt: ApiJson.nullableString(
        json,
        'access_token_expires_at',
      ),
      refreshTokenExpiresAt: ApiJson.nullableString(
        json,
        'refresh_token_expires_at',
      ),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String? accessTokenExpiresAt;
  final String? refreshTokenExpiresAt;
}

class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  factory AuthSession.fromJson(JsonMap json) {
    return AuthSession(
      user: AuthUser.fromJson(ApiJson.readMap(json, 'user')),
      tokens: AuthTokens.fromJson(ApiJson.readMap(json, 'tokens')),
    );
  }

  final AuthUser user;
  final AuthTokens tokens;
}

class AuthSessionRecord {
  const AuthSessionRecord({
    required this.id,
    required this.userId,
    required this.tokenSuffix,
    required this.expiresAt,
    required this.createdAt,
    this.userAgent,
    this.ipAddress,
    this.revokedAt,
    this.lastUsedAt,
  });

  factory AuthSessionRecord.fromJson(JsonMap json) {
    return AuthSessionRecord(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      tokenSuffix: ApiJson.readString(json, 'token_suffix'),
      userAgent: ApiJson.nullableString(json, 'user_agent'),
      ipAddress: ApiJson.nullableString(json, 'ip_address'),
      expiresAt: ApiJson.readString(json, 'expires_at'),
      createdAt: ApiJson.readString(json, 'created_at'),
      revokedAt: ApiJson.nullableString(json, 'revoked_at'),
      lastUsedAt: ApiJson.nullableString(json, 'last_used_at'),
    );
  }

  final String id;
  final String userId;
  final String tokenSuffix;
  final String? userAgent;
  final String? ipAddress;
  final String expiresAt;
  final String createdAt;
  final String? revokedAt;
  final String? lastUsedAt;
}

class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  JsonMap toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  const RegisterRequest({required this.email, required this.password});

  final String email;
  final String password;

  JsonMap toJson() => {'email': email, 'password': password};
}

class UpdateAccountRequest {
  const UpdateAccountRequest({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;

  JsonMap toJson() => {'name': name, 'avatar_url': avatarUrl};
}

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  JsonMap toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
  };
}
