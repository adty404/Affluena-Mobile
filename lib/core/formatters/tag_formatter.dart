/// Normalizes a tag name to a single leading `#` for display.
///
/// Collapses any leading `#`s and trims whitespace; an empty name renders as
/// `#`. Shared so tag chips/labels look identical everywhere.
String tagLabel(String name) {
  final normalized = name.trim().replaceFirst(RegExp(r'^#+'), '');
  return normalized.isEmpty ? '#' : '#$normalized';
}
