import '../../../core/api/api_json.dart';

/// A partner link as seen by the caller. [direction] is 'owned' (the caller
/// invited this person to view the caller's wallets) or 'incoming' (this person
/// shares their wallets with the caller). [userId]/[email]/[name] are the OTHER
/// party.
class PartnerLink {
  const PartnerLink({
    required this.id,
    required this.direction,
    required this.status,
    required this.userId,
    required this.email,
    required this.name,
  });

  final String id;
  final String direction;
  final String status;
  final String userId;
  final String email;
  final String name;

  bool get isOwned => direction == 'owned';
  bool get isIncoming => direction == 'incoming';
  bool get isJoined => status == 'joined';
  bool get isPending => status == 'pending';

  /// A readable label for the other party (name, falling back to email).
  String get displayName => name.isNotEmpty ? name : email;

  factory PartnerLink.fromJson(JsonMap json) {
    return PartnerLink(
      id: ApiJson.readString(json, 'id'),
      direction: ApiJson.readString(json, 'direction'),
      status: ApiJson.readString(json, 'status'),
      userId: ApiJson.readString(json, 'user_id'),
      email: ApiJson.readString(json, 'email'),
      name: ApiJson.readString(json, 'name'),
    );
  }
}

class PartnerListResponse {
  const PartnerListResponse({required this.partners});

  final List<PartnerLink> partners;

  factory PartnerListResponse.fromJson(JsonMap json) {
    final raw = json['partners'];
    final partners = raw is List
        ? raw
              .whereType<JsonMap>()
              .map(PartnerLink.fromJson)
              .toList(growable: false)
        : const <PartnerLink>[];
    return PartnerListResponse(partners: partners);
  }
}

class PartnerInviteRequest {
  const PartnerInviteRequest({required this.email});
  final String email;
  JsonMap toJson() => {'email': email};
}

class PartnerRespondRequest {
  const PartnerRespondRequest({required this.status});
  final String status;
  JsonMap toJson() => {'status': status};
}
