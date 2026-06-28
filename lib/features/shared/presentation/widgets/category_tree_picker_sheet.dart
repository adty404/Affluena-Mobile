import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

/// One selectable category in the tree picker. Decoupled from any data model so
/// every screen (add transaction, quick-entry template, category parent picker)
/// can reuse it by mapping its own categories to this shape.
class CategoryTreeEntry {
  const CategoryTreeEntry({
    required this.id,
    required this.name,
    this.parentId,
  });

  final String id;
  final String name;
  final String? parentId;
}

/// Result sentinel for [showCategoryTreePicker].
/// - returns `null` when the user dismisses without choosing (no change)
/// - returns an empty string when the user taps "No category" (clear)
/// - returns the category id when a category is chosen
const String categoryTreeClearedValue = '';

/// A tree-aware category picker. Renders parents with indented children
/// (categories are a hierarchy), supports collapse/expand and search, and an
/// optional "No category" row for fields where a category is optional.
Future<String?> showCategoryTreePicker({
  required BuildContext context,
  required String title,
  required List<CategoryTreeEntry> categories,
  String? selectedId,
  bool allowNone = false,
  String noneLabel = 'Tanpa kategori',
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
    ),
  );
}

class _CategoryTreePickerSheet extends StatefulWidget {
  const _CategoryTreePickerSheet({
    required this.title,
    required this.categories,
    required this.allowNone,
    required this.noneLabel,
    this.selectedId,
  });

  final String title;
  final List<CategoryTreeEntry> categories;
  final String? selectedId;
  final bool allowNone;
  final String noneLabel;

  @override
  State<_CategoryTreePickerSheet> createState() =>
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

class _CategoryTreePickerSheetState extends State<_CategoryTreePickerSheet> {
  String _query = '';
  final Set<String> _collapsed = <String>{};

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
            Text(widget.title, style: textTheme.titleLarge),
            const SizedBox(height: AffluenaSpacing.space4),
            TextField(
              key: const Key('category-tree-search-field'),
              autocorrect: false,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari kategori',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
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
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        bottom: AffluenaSpacing.space2,
                      ),
                      shrinkWrap: true,
                      itemCount: nodes.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AffluenaSpacing.space2),
                      itemBuilder: (context, index) {
                        final node = nodes[index];
                        return _CategoryTreeTile(
                          node: node,
                          selected: node.entry.id == widget.selectedId,
                          onTap: () => Navigator.of(context).pop(node.entry.id),
                          onToggle: node.hasChildren
                              ? () => setState(() {
                                  if (_collapsed.contains(node.entry.id)) {
                                    _collapsed.remove(node.entry.id);
                                  } else {
                                    _collapsed.add(node.entry.id);
                                  }
                                })
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_FlatNode> _buildSearchResults(String query) {
    return widget.categories
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
    final ids = {for (final c in widget.categories) c.id};
    final childrenByParent = <String, List<CategoryTreeEntry>>{};
    final roots = <CategoryTreeEntry>[];
    for (final c in widget.categories) {
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
                  if (node.depth > 0) ...[
                    Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: colors.inkMuted,
                    ),
                    const SizedBox(width: AffluenaSpacing.space2),
                  ],
                  Expanded(
                    child: Text(
                      node.entry.name,
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
