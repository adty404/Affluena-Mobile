/// Normalizes a tag name to a single leading `#` for display.
///
/// Collapses any leading `#`s and trims whitespace; an empty name renders as
/// `#`. Shared so tag chips/labels look identical everywhere.
String tagLabel(String name) {
  final normalized = normalizedTagName(name);
  return normalized.isEmpty ? '#' : '#$normalized';
}

/// The bare tag name with any leading `#`s and surrounding whitespace removed.
String normalizedTagName(String name) {
  return name.trim().replaceFirst(RegExp(r'^#+'), '');
}
