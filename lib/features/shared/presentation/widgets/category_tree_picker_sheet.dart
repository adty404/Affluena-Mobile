import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../categories/data/category_models.dart';
import '../../../categories/presentation/category_tag_management_screen.dart';
import '../appearance/item_appearance.dart';

/// One selectable category in the tree picker. Decoupled from any data model so
/// every screen (add transaction, quick-entry template, category parent picker)
/// can reuse it by mapping its own categories to this shape — most callers use
/// [CategoryTreeEntry.fromCategory].
class CategoryTreeEntry {
  const CategoryTreeEntry({
    required this.id,
    required this.name,
    this.parentId,
    this.icon = '',
    this.color = '',
    this.type,
  });

  factory CategoryTreeEntry.fromCategory(Category category) {
    return CategoryTreeEntry(
      id: category.id,
      name: category.name,
      parentId: category.parentId,
      icon: category.icon,
      color: category.color,
      type: category.type,
    );
  }

  final String id;
  final String name;
  final String? parentId;

  /// Semantic icon id from the shared catalog ('' = none chosen).
  final String icon;

  /// `#RRGGBB` accent ('' = none chosen).
  final String color;

  /// Used for the fallback glyph; null when the caller has no type handy.
  final CategoryType? type;
}

/// Result sentinel for [showCategoryTreePicker].
/// - returns `null` when the user dismisses without choosing (no change)
/// - returns an empty string when the user taps "No category" (clear)
/// - returns the category id when a category is chosen
const String categoryTreeClearedValue = '';

/// A tree-aware category picker. Renders parents with indented children
/// (categories are a hierarchy), supports collapse/expand and search, and an
/// optional "No category" row for fields where a category is optional.
///
/// Categories carry the user's chosen icon/color and arrive in the user's
/// arranged order (API position order). The picker is **selection-only** — it
/// neither reorders nor creates in place; a "Kelola kategori" button in the
/// header opens the management screen ([CategoryTagManagementScreen]) for full
/// CRUD + drag-to-reorder. [onMutated] runs after returning from that screen so
/// the calling screen can refresh its own category state.
Future<String?> showCategoryTreePicker({
  required BuildContext context,
  required String title,
  required List<CategoryTreeEntry> categories,
  String? selectedId,
  bool allowNone = false,
  String noneLabel = 'Tanpa kategori',
  Future<void> Function()? onMutated,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _CategoryTreePickerSheet(
      title: title,
      categories: categories,
      selectedId: selectedId,
      allowNone: allowNone,
      noneLabel: noneLabel,
      onMutated: onMutated,
    ),
  );
}

class _CategoryTreePickerSheet extends ConsumerStatefulWidget {
  const _CategoryTreePickerSheet({
    required this.title,
    required this.categories,
    required this.allowNone,
    required this.noneLabel,
    this.selectedId,
    this.onMutated,
  });

  final String title;
  final List<CategoryTreeEntry> categories;
  final String? selectedId;
  final bool allowNone;
  final String noneLabel;
  final Future<void> Function()? onMutated;

  @override
  ConsumerState<_CategoryTreePickerSheet> createState() =>
      _CategoryTreePickerSheetState();
}

class _FlatNode {
  const _FlatNode({
    required this.entry,
    required this.depth,
    required this.hasChildren,
    required this.collapsed,
  });

  final CategoryTreeEntry entry;
  final int depth;
  final bool hasChildren;
  final bool collapsed;
}

class _CategoryTreePickerSheetState
    extends ConsumerState<_CategoryTreePickerSheet> {
  String _query = '';

  /// Search starts collapsed behind a header icon so the field doesn't crowd
  /// the list; tapping the search icon reveals it (and clearing it hides it).
  bool _searchVisible = false;
  final Set<String> _collapsed = <String>{};

  /// The categories this picker renders (reorder/CRUD live on the dedicated
  /// management screen, reached via the header's "Kelola kategori" button).
  late final List<CategoryTreeEntry> _entries = List.of(widget.categories);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxListHeight = (screenHeight * 0.55).clamp(280.0, 460.0);
    final normalizedQuery = _query.trim().toLowerCase();

    final nodes = normalizedQuery.isEmpty
        ? _buildTree()
        : _buildSearchResults(normalizedQuery);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AffluenaSpacing.space5,
          right: AffluenaSpacing.space5,
          bottom:
              MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: textTheme.titleLarge),
                ),
                // Search is a header icon (not an always-on field): tapping it
                // toggles the input; collapsing clears the query.
                IconButton(
                  key: const Key('category-picker-search-button'),
                  tooltip: _searchVisible ? 'Tutup pencarian' : 'Cari kategori',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    _searchVisible = !_searchVisible;
                    if (!_searchVisible) _query = '';
                  }),
                  icon: Icon(
                    _searchVisible ? Icons.close : Icons.search,
                    color: colors.inkMuted,
                  ),
                ),
                // Manage categories (full CRUD + drag-to-reorder) on a dedicated
                // screen. The picker itself stays selection-only — no direct
                // reorder here.
                IconButton(
                  key: const Key('category-picker-manage-button'),
                  tooltip: 'Kelola kategori',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await context.push(CategoryTagManagementScreen.path);
                    await widget.onMutated?.call();
                  },
                  icon: Icon(Icons.settings_outlined, color: colors.inkMuted),
                ),
              ],
            ),
            if (_searchVisible) ...[
              const SizedBox(height: AffluenaSpacing.space3),
              TextField(
                key: const Key('category-tree-search-field'),
                autofocus: true,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari kategori',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ],
            const SizedBox(height: AffluenaSpacing.space4),
            if (widget.allowNone && normalizedQuery.isEmpty) ...[
              _NoneTile(
                label: widget.noneLabel,
                selected: widget.selectedId == null || widget.selectedId == '',
                onTap: () =>
                    Navigator.of(context).pop(categoryTreeClearedValue),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: nodes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AffluenaSpacing.space5,
                      ),
                      child: Center(
                        child: Text(
                          'Kategori tidak ditemukan.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(
                        bottom: AffluenaSpacing.space2,
                      ),
                      shrinkWrap: true,
                      children: [
                        for (final node in nodes)
                          Padding(
                            key: ValueKey('picker-row-${node.entry.id}'),
                            padding: const EdgeInsets.only(
                              bottom: AffluenaSpacing.space2,
                            ),
                            child: _CategoryTreeTile(
                              node: node,
                              selected: node.entry.id == widget.selectedId,
                              onTap: () =>
                                  Navigator.of(context).pop(node.entry.id),
                              onToggle: node.hasChildren
                                  ? () => setState(() {
                                      if (_collapsed.contains(node.entry.id)) {
                                        _collapsed.remove(node.entry.id);
                                      } else {
                                        _collapsed.add(node.entry.id);
                                      }
                                    })
                                  : null,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_FlatNode> _buildSearchResults(String query) {
    return _entries
        .where((c) => c.name.toLowerCase().contains(query))
        .map(
          (c) => _FlatNode(
            entry: c,
            depth: 0,
            hasChildren: false,
            collapsed: false,
          ),
        )
        .toList(growable: false);
  }

  List<_FlatNode> _buildTree() {
    final ids = {for (final c in _entries) c.id};
    final childrenByParent = <String, List<CategoryTreeEntry>>{};
    final roots = <CategoryTreeEntry>[];
    for (final c in _entries) {
      final parent = c.parentId;
      if (parent == null || !ids.contains(parent)) {
        roots.add(c);
      } else {
        childrenByParent.putIfAbsent(parent, () => []).add(c);
      }
    }

    final flat = <_FlatNode>[];
    void walk(CategoryTreeEntry entry, int depth) {
      final children = childrenByParent[entry.id] ?? const [];
      final hasChildren = children.isNotEmpty;
      final collapsed = _collapsed.contains(entry.id);
      flat.add(
        _FlatNode(
          entry: entry,
          depth: depth,
          hasChildren: hasChildren,
          collapsed: collapsed,
        ),
      );
      if (hasChildren && !collapsed) {
        for (final child in children) {
          walk(child, depth + 1);
        }
      }
    }

    for (final root in roots) {
      walk(root, 0);
    }
    return flat;
  }
}

class _CategoryTreeTile extends StatelessWidget {
  const _CategoryTreeTile({
    required this.node,
    required this.selected,
    required this.onTap,
    this.onToggle,
  });

  final _FlatNode node;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final radius = BorderRadius.circular(AffluenaRadii.lg);
    final indent = node.depth * AffluenaSpacing.space4;
    final entry = node.entry;
    // Categories with a chosen appearance get a tinted icon chip; untouched
    // ones keep the original minimal row so the list stays calm.
    final hasAppearance = entry.icon.isNotEmpty || entry.color.isNotEmpty;
    final chipIcon =
        categoryIconFor(entry.icon) ??
        (entry.type != null
            ? categoryTypeFallbackIcon(entry.type!)
            : Icons.category_outlined);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.forestSoft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? colors.forest : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: EdgeInsets.only(
                left: AffluenaSpacing.space3 + indent,
                right: AffluenaSpacing.space2,
                top: AffluenaSpacing.space2,
                bottom: AffluenaSpacing.space2,
              ),
              child: Row(
                children: [
                  if (hasAppearance) ...[
                    ItemAccentIconTile(
                      icon: chipIcon,
                      colorHex: entry.color,
                      fallback: colors.forest,
                      fallbackBackground: colors.forestSoft,
                    ),
                    const SizedBox(width: AffluenaSpacing.space3),
                  ] else if (node.depth > 0) ...[
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: colors.inkMuted,
                    ),
                    const SizedBox(width: AffluenaSpacing.space2),
                  ],
                  Expanded(
                    child: Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: node.depth == 0
                          ? textTheme.bodyLarge
                          : textTheme.bodyMedium,
                    ),
                  ),
                  if (selected) ...[
                    Icon(Icons.check_circle, color: colors.forest, size: 20),
                    const SizedBox(width: AffluenaSpacing.space1),
                  ],
                  if (onToggle != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        node.collapsed ? Icons.expand_more : Icons.expand_less,
                        color: colors.inkMuted,
                      ),
                      onPressed: onToggle,
                      tooltip: node.collapsed ? 'Buka' : 'Tutup',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoneTile extends StatelessWidget {
  const _NoneTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final radius = BorderRadius.circular(AffluenaRadii.lg);

    return Material(
      color: selected ? colors.forestSoft : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: selected ? colors.forest : colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AffluenaSpacing.space3,
              vertical: AffluenaSpacing.space2,
            ),
            child: Row(
              children: [
                Icon(Icons.block, size: 18, color: colors.inkMuted),
                const SizedBox(width: AffluenaSpacing.space3),
                Expanded(child: Text(label, style: textTheme.bodyLarge)),
                if (selected)
                  Icon(Icons.check_circle, color: colors.forest, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
