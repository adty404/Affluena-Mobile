typedef JsonMap = Map<String, Object?>;

abstract final class ApiJson {
  static JsonMap readMap(JsonMap json, String key) {
    final value = json[key];
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    throw FormatException('Expected "$key" to be an object.');
  }

  static JsonMap? optionalMap(JsonMap json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    throw FormatException('Expected "$key" to be an object.');
  }

  static List<JsonMap> readObjectList(JsonMap json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('Expected "$key" to be a list.');
    }
    return value
        .map((item) {
          if (item is Map<String, Object?>) return item;
          if (item is Map) return Map<String, Object?>.from(item);
          throw FormatException('Expected "$key" list item to be an object.');
        })
        .toList(growable: false);
  }

  static String readString(JsonMap json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Expected "$key" to be a string.');
  }

  static String optionalString(
    JsonMap json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is String) return value;
    throw FormatException('Expected "$key" to be a string.');
  }

  static String? nullableString(JsonMap json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Expected "$key" to be a string.');
  }

  static int readInt(JsonMap json, String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('Expected "$key" to be an integer.');
  }

  static int optionalInt(JsonMap json, String key, {int fallback = 0}) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is int) return value;
    throw FormatException('Expected "$key" to be an integer.');
  }

  static double readDouble(JsonMap json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    throw FormatException('Expected "$key" to be a number.');
  }

  static List<String> readStringList(JsonMap json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('Expected "$key" to be a list.');
    }
    return value
        .map((item) {
          if (item is String) return item;
          throw FormatException('Expected "$key" list item to be a string.');
        })
        .toList(growable: false);
  }
}
