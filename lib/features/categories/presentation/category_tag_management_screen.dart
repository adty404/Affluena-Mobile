import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/appearance/item_appearance.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_chip_bar.dart';
import '../../shared/presentation/widgets/affluena_choice_chip.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/category_tag_management_controller.dart';
import '../data/category_models.dart';

part 'category_tag_forms.dart';
part 'category_tag_widgets.dart';

class CategoryTagManagementScreen extends ConsumerStatefulWidget {
  const CategoryTagManagementScreen({super.key});

  static const path = '/categories-tags';

  @override
  ConsumerState<CategoryTagManagementScreen> createState() =>
      _CategoryTagManagementScreenState();
}

class _CategoryTagManagementScreenState
    extends ConsumerState<CategoryTagManagementScreen> {
  String _query = '';
  CategoryType? _typeFilter;

  /// Ids of parent categories whose subtree is collapsed. Defaults to expanded,
  /// so only explicitly-collapsed nodes live here.
  final Set<String> _collapsed = <String>{};

  /// The category behind each reorderable row from the last build (null for
  /// non-category rows like section headers), so [_onReorder] can translate a
  /// drop index in the flattened list into a sibling position.
  List<Category?> _rowCategories = const [];

  void _toggleCollapsed(String id) {
    setState(() {
      if (!_collapsed.remove(id)) _collapsed.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryTagManagementControllerProvider);
    final controller = ref.read(
      categoryTagManagementControllerProvider.notifier,
    );

    if (state.isLoading && state.categories.isEmpty && state.tags.isEmpty) {
      return const _CategoryTagLoading();
    }

    if (state.loadError != null &&
        state.categories.isEmpty &&
        state.tags.isEmpty) {
      return _CategoryTagError(onRetry: controller.load);
    }

    final normalizedQuery = _query.trim().toLowerCase();
    final visibleCategories = state.categories
        .where((category) {
          if (_typeFilter != null && category.type != _typeFilter) return false;
          if (normalizedQuery.isEmpty) return true;
          final parentName = state
              .categoryName(category.parentId)
              .toLowerCase();
          return category.name.toLowerCase().contains(normalizedQuery) ||
              parentName.contains(normalizedQuery) ||
              category.type.apiValue.contains(normalizedQuery);
        })
        .toList(growable: false);

    final isFiltering = normalizedQuery.isNotEmpty || _typeFilter != null;
    final rows = _buildRows(
      context: context,
      state: state,
      controller: controller,
      visibleCategories: visibleCategories,
      isFiltering: isFiltering,
    );
    _rowCategories = [for (final row in rows) row.category];
    // Rearranging only makes sense on the full hierarchy: a search/filtered
    // list is a pruned view where sibling order is not visible.
    final canReorder = !isFiltering && !state.isSaving;

    return DrillInScaffold(
      title: 'Kategori',
      actions: [
        IconButton.filledTonal(
          key: const Key('add-category-button'),
          tooltip: 'Tambah kategori',
          onPressed: state.isSaving
              ? null
              : () => _showCategoryForm(context, ref, state: state),
          icon: const Icon(Icons.account_tree_outlined),
        ),
        const SizedBox(width: AffluenaSpacing.space2),
      ],
      body: ReorderableListView(
        padding: AffluenaInsets.screen,
        buildDefaultDragHandles: false,
        onReorderItem: _onReorder,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('category-tag-search-field'),
              autocorrect: false,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Cari kategori',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            AffluenaChipBar(
              chips: [
                AffluenaChoiceChip(
                  label: 'Semua',
                  selected: _typeFilter == null,
                  onSelected: () => setState(() => _typeFilter = null),
                ),
                AffluenaChoiceChip(
                  label: 'Pengeluaran',
                  selected: _typeFilter == CategoryType.expense,
                  onSelected: () =>
                      setState(() => _typeFilter = CategoryType.expense),
                ),
                AffluenaChoiceChip(
                  label: 'Pemasukan',
                  selected: _typeFilter == CategoryType.income,
                  onSelected: () =>
                      setState(() => _typeFilter = CategoryType.income),
                ),
              ],
            ),
            if (state.actionError != null) ...[
              const SizedBox(height: AffluenaSpacing.space4),
              AffluenaBanner.error(
                state.actionError!,
                onRetry: controller.load,
              ),
            ],
            const SizedBox(height: AffluenaSpacing.space6),
            SectionHeader(
              title: 'Kategori',
              actionLabel: '${visibleCategories.length} ditampilkan',
            ),
            if (!isFiltering && visibleCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AffluenaSpacing.space1),
                child: Text(
                  'Tahan lalu geser kartu untuk mengatur urutan.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.affluenaColors.inkMuted,
                  ),
                ),
              ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
        ),
        footer:
            (state.hasMoreCategories &&
                normalizedQuery.isEmpty &&
                _typeFilter == null)
            ? Padding(
                padding: const EdgeInsets.only(top: AffluenaSpacing.space3),
                child: OutlinedButton(
                  key: const Key('category-load-more-button'),
                  onPressed: state.isLoadingMoreCategories
                      ? null
                      : controller.loadMoreCategories,
                  child: Text(
                    state.isLoadingMoreCategories
                        ? 'Memuat...'
                        : 'Muat lebih banyak (${state.categories.length} dari ${state.categoryTotal})',
                  ),
                ),
              )
            : null,
        children: [
          for (final (index, row) in rows.indexed)
            Padding(
              key: row.key,
              padding: EdgeInsets.only(bottom: row.bottomSpacing),
              child: (canReorder && row.category != null)
                  ? ReorderableDelayedDragStartListener(
                      index: index,
                      child: row.child,
                    )
                  : row.child,
            ),
        ],
      ),
    );
  }

  /// Translates a drop in the flattened list into a move among the dragged
  /// category's own siblings (same parent, same type): the new sibling slot is
  /// the number of same-group rows remaining above the drop point. Drops
  /// outside the sibling range clamp to the group's start/end, so a category
  /// can never be re-parented or change type by dragging.
  ///
  /// [newIndex] follows onReorderItem semantics: already adjusted for the
  /// removal of the dragged row at [oldIndex].
  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _rowCategories.length) return;
    final dragged = _rowCategories[oldIndex];
    if (dragged == null) return;

    final state = ref.read(categoryTagManagementControllerProvider);
    final loadedIds = {for (final c in state.categories) c.id};
    final draggedParent = _parentKey(dragged, loadedIds);

    final without = [..._rowCategories]..removeAt(oldIndex);
    var siblingSlot = 0;
    for (var i = 0; i < newIndex && i < without.length; i++) {
      final candidate = without[i];
      if (candidate != null &&
          candidate.type == dragged.type &&
          _parentKey(candidate, loadedIds) == draggedParent) {
        siblingSlot++;
      }
    }

    unawaited(_persistReorder(dragged, siblingSlot));
  }

  /// Moves [dragged] to [siblingSlot] within its sibling group, flattens the
  /// whole loaded hierarchy back into one canonical order (income then expense,
  /// each parent directly followed by its subtree), and persists it. The
  /// controller applies the new order optimistically and reverts on failure.
  Future<void> _persistReorder(Category dragged, int siblingSlot) async {
    final controller = ref.read(
      categoryTagManagementControllerProvider.notifier,
    );
    final categories = ref
        .read(categoryTagManagementControllerProvider)
        .categories;
    final loadedIds = {for (final c in categories) c.id};

    final childrenOf = <(CategoryType, String?), List<Category>>{};
    for (final category in categories) {
      childrenOf
          .putIfAbsent((
            category.type,
            _parentKey(category, loadedIds),
          ), () => <Category>[])
          .add(category);
    }

    final group =
        childrenOf[(dragged.type, _parentKey(dragged, loadedIds))] ??
        <Category>[];
    group.removeWhere((category) => category.id == dragged.id);
    group.insert(siblingSlot.clamp(0, group.length), dragged);

    final ordered = <Category>[];
    final visited = <String>{};
    void walk(CategoryType type, String? parentKey) {
      for (final category
          in childrenOf[(type, parentKey)] ?? const <Category>[]) {
        if (!visited.add(category.id)) continue;
        ordered.add(category);
        walk(type, category.id);
      }
    }

    for (final type in const [CategoryType.income, CategoryType.expense]) {
      walk(type, null);
    }

    final persisted = await controller.reorderCategories(ordered);
    if (!persisted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Urutan kategori gagal disimpan.')),
      );
    }
  }

  /// A category's effective parent for grouping: its parentId when that parent
  /// is part of the loaded list, otherwise null (rendered as a root).
  static String? _parentKey(Category category, Set<String> loadedIds) {
    final parentId = category.parentId;
    return (parentId != null && loadedIds.contains(parentId)) ? parentId : null;
  }

  /// Builds the reorderable rows. When the user is searching or filtering by a
  /// single type, the hierarchy is hard to scan, so we fall back to a flat,
  /// pruned list. Otherwise we draw the full Income/Expense hierarchy trees.
  List<_CategoryListRow> _buildRows({
    required BuildContext context,
    required CategoryTagManagementState state,
    required CategoryTagManagementController controller,
    required List<Category> visibleCategories,
    required bool isFiltering,
  }) {
    if (visibleCategories.isEmpty) {
      return [
        _CategoryListRow(
          key: const ValueKey('category-empty-state'),
          bottomSpacing: 0,
          child: _EmptyManagementState(
            icon: Icons.account_tree_outlined,
            title: isFiltering
                ? 'Tidak ada kategori yang cocok'
                : 'Belum ada kategori',
            message: isFiltering
                ? 'Coba kata kunci atau filter lain untuk menemukan kategori.'
                : 'Kelompokkan pengeluaran dan pemasukan kamu ke dalam hierarki. '
                      'Kategori bisa bertingkat hingga 3 level — induk, '
                      'subkategorinya, dan subkategori dari subkategori itu. '
                      'Buat yang pertama untuk memulai.',
            actionLabel: isFiltering ? null : 'Tambah kategori',
            onAction: isFiltering
                ? null
                : () => _showCategoryForm(context, ref, state: state),
          ),
        ),
      ];
    }

    // Filtering/searching: a flat, depth-aware list is more useful than a
    // partial tree (matches may be scattered across branches).
    if (isFiltering) {
      return [
        for (final category in visibleCategories)
          _CategoryListRow(
            key: ValueKey('category-row-${category.id}'),
            category: category,
            bottomSpacing: AffluenaSpacing.space3,
            child: _CategoryTreeNode(
              category: category,
              depth: 0,
              isLast: true,
              hasChildren: false,
              childCount: 0,
              collapsed: false,
              showConnectors: false,
              parentName: state.categoryName(category.parentId),
              canAddChild: state.canParent(category),
              onToggle: null,
              onAddChild: state.canParent(category)
                  ? () => _showCategoryForm(
                      context,
                      ref,
                      state: state,
                      presetParent: category,
                    )
                  : null,
              onEdit: () => _showCategoryForm(
                context,
                ref,
                state: state,
                category: category,
              ),
              onDelete: () =>
                  _confirmDeleteCategory(context, controller, category),
            ),
          ),
      ];
    }

    // Full hierarchy: group by type, then render each section as a tree.
    final rows = <_CategoryListRow>[];
    for (final type in const [CategoryType.income, CategoryType.expense]) {
      final categories = visibleCategories
          .where((c) => c.type == type)
          .toList(growable: false);
      if (categories.isEmpty) continue;
      if (rows.isNotEmpty) {
        rows.last = rows.last.withBottomSpacing(AffluenaSpacing.space5);
      }
      rows.addAll(
        _buildTypeTreeRows(
          context: context,
          state: state,
          controller: controller,
          type: type,
          categories: categories,
        ),
      );
    }
    return rows;
  }

  List<_CategoryListRow> _buildTypeTreeRows({
    required BuildContext context,
    required CategoryTagManagementState state,
    required CategoryTagManagementController controller,
    required CategoryType type,
    required List<Category> categories,
  }) {
    // Index this type's categories by parent so we can walk the tree. Only
    // parents that are themselves part of [categories] anchor a subtree; any
    // node whose parent is missing is treated as a root so it stays visible.
    final ids = {for (final c in categories) c.id};
    final childrenOf = <String?, List<Category>>{};
    for (final category in categories) {
      final key = (category.parentId != null && ids.contains(category.parentId))
          ? category.parentId
          : null;
      childrenOf.putIfAbsent(key, () => <Category>[]).add(category);
    }

    final roots = childrenOf[null] ?? const <Category>[];
    final total = categories.length;

    final rows = <_CategoryListRow>[
      _CategoryListRow(
        key: ValueKey('category-section-${type.apiValue}'),
        bottomSpacing: AffluenaSpacing.space3,
        child: _TreeSectionHeader(
          type: type,
          parentCount: roots.length,
          total: total,
        ),
      ),
    ];

    void addNode(Category category, int depth, bool isLast) {
      final children = childrenOf[category.id] ?? const <Category>[];
      final hasChildren = children.isNotEmpty;
      final collapsed = _collapsed.contains(category.id);
      // Cap "Add subcategory" at the 3-level limit using the controller guard.
      final canAddChild = state.canParent(category);

      rows.add(
        _CategoryListRow(
          key: ValueKey('category-row-${category.id}'),
          category: category,
          bottomSpacing: AffluenaSpacing.space2,
          child: _CategoryTreeNode(
            category: category,
            depth: depth,
            isLast: isLast,
            hasChildren: hasChildren,
            childCount: children.length,
            collapsed: collapsed,
            showConnectors: depth > 0,
            parentName: state.categoryName(category.parentId),
            canAddChild: canAddChild,
            onToggle: hasChildren ? () => _toggleCollapsed(category.id) : null,
            onAddChild: canAddChild
                ? () => _showCategoryForm(
                    context,
                    ref,
                    state: state,
                    presetParent: category,
                  )
                : null,
            onEdit: () => _showCategoryForm(
              context,
              ref,
              state: state,
              category: category,
            ),
            onDelete: () =>
                _confirmDeleteCategory(context, controller, category),
          ),
        ),
      );

      if (hasChildren && !collapsed) {
        for (var i = 0; i < children.length; i++) {
          addNode(children[i], depth + 1, i == children.length - 1);
        }
      }
    }

    for (var i = 0; i < roots.length; i++) {
      addNode(roots[i], 0, i == roots.length - 1);
    }

    return rows;
  }
}

/// One row of the reorderable category list: the widget, its key, the category
/// it represents (null for section headers/empty state), and the gap below it
/// (folded into the row because a ReorderableListView cannot hold bare
/// spacer children).
class _CategoryListRow {
  const _CategoryListRow({
    required this.key,
    required this.child,
    required this.bottomSpacing,
    this.category,
  });

  final Key key;
  final Widget child;
  final double bottomSpacing;
  final Category? category;

  _CategoryListRow withBottomSpacing(double spacing) => _CategoryListRow(
    key: key,
    category: category,
    bottomSpacing: spacing,
    child: child,
  );
}
