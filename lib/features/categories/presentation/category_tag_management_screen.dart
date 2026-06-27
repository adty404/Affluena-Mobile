import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
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

    return DrillInScaffold(
      title: 'Categories',
      actions: [
        IconButton.filledTonal(
          key: const Key('add-category-button'),
          tooltip: 'Add category',
          onPressed: state.isSaving
              ? null
              : () => _showCategoryForm(context, ref, state: state),
          icon: const Icon(Icons.account_tree_outlined),
        ),
        const SizedBox(width: AffluenaSpacing.space2),
      ],
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          TextField(
            key: const Key('category-tag-search-field'),
            autocorrect: false,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search categories',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Wrap(
            spacing: AffluenaSpacing.space2,
            runSpacing: AffluenaSpacing.space2,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _typeFilter == null,
                onSelected: (_) => setState(() => _typeFilter = null),
              ),
              ChoiceChip(
                label: const Text('Expense'),
                selected: _typeFilter == CategoryType.expense,
                onSelected: (_) =>
                    setState(() => _typeFilter = CategoryType.expense),
              ),
              ChoiceChip(
                label: const Text('Income'),
                selected: _typeFilter == CategoryType.income,
                onSelected: (_) =>
                    setState(() => _typeFilter = CategoryType.income),
              ),
            ],
          ),
          if (state.actionError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner.error(state.actionError!, onRetry: controller.load),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Categories',
            actionLabel: '${visibleCategories.length} shown',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          ..._buildCategoriesSection(
            context: context,
            state: state,
            controller: controller,
            visibleCategories: visibleCategories,
            normalizedQuery: normalizedQuery,
          ),
          if (state.hasMoreCategories &&
              normalizedQuery.isEmpty &&
              _typeFilter == null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            OutlinedButton(
              key: const Key('category-load-more-button'),
              onPressed: state.isLoadingMoreCategories
                  ? null
                  : controller.loadMoreCategories,
              child: Text(
                state.isLoadingMoreCategories
                    ? 'Loading...'
                    : 'Load more (${state.categories.length} of ${state.categoryTotal})',
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Renders the categories block. When the user is searching or filtering by a
  /// single type, the hierarchy is hard to scan, so we fall back to a flat,
  /// pruned list. Otherwise we draw the full Income/Expense hierarchy trees.
  List<Widget> _buildCategoriesSection({
    required BuildContext context,
    required CategoryTagManagementState state,
    required CategoryTagManagementController controller,
    required List<Category> visibleCategories,
    required String normalizedQuery,
  }) {
    final isFiltering = normalizedQuery.isNotEmpty || _typeFilter != null;

    if (visibleCategories.isEmpty) {
      return [
        _EmptyManagementState(
          icon: Icons.account_tree_outlined,
          title: isFiltering ? 'No categories match' : 'No categories yet',
          message: isFiltering
              ? 'Try a different search or filter to find a category.'
              : 'Group your spending and income into a hierarchy. Categories '
                    'nest up to 3 levels — a parent, its subcategories, and '
                    'their subcategories. Create your first one to start.',
          actionLabel: isFiltering ? null : 'Add category',
          onAction: isFiltering
              ? null
              : () => _showCategoryForm(context, ref, state: state),
        ),
      ];
    }

    // Filtering/searching: a flat, depth-aware list is more useful than a
    // partial tree (matches may be scattered across branches).
    if (isFiltering) {
      final widgets = <Widget>[];
      for (final category in visibleCategories) {
        widgets.add(
          _CategoryTreeNode(
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
        );
        widgets.add(const SizedBox(height: AffluenaSpacing.space3));
      }
      return widgets;
    }

    // Full hierarchy: group by type, then render each section as a tree.
    final byType = <CategoryType, List<Category>>{
      CategoryType.income: const [],
      CategoryType.expense: const [],
    };
    for (final type in CategoryType.values) {
      byType[type] = visibleCategories
          .where((c) => c.type == type)
          .toList(growable: false);
    }

    final widgets = <Widget>[];
    for (final type in const [CategoryType.income, CategoryType.expense]) {
      final categories = byType[type]!;
      if (categories.isEmpty) continue;
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: AffluenaSpacing.space5));
      }
      widgets.addAll(
        _buildTypeTree(
          context: context,
          state: state,
          controller: controller,
          type: type,
          categories: categories,
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildTypeTree({
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

    final rows = <Widget>[];

    void addNode(Category category, int depth, bool isLast) {
      final children = childrenOf[category.id] ?? const <Category>[];
      final hasChildren = children.isNotEmpty;
      final collapsed = _collapsed.contains(category.id);
      // Cap "Add subcategory" at the 3-level limit using the controller guard.
      final canAddChild = state.canParent(category);

      rows.add(
        _CategoryTreeNode(
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
          onEdit: () =>
              _showCategoryForm(context, ref, state: state, category: category),
          onDelete: () => _confirmDeleteCategory(context, controller, category),
        ),
      );
      rows.add(const SizedBox(height: AffluenaSpacing.space2));

      if (hasChildren && !collapsed) {
        for (var i = 0; i < children.length; i++) {
          addNode(children[i], depth + 1, i == children.length - 1);
        }
      }
    }

    for (var i = 0; i < roots.length; i++) {
      addNode(roots[i], 0, i == roots.length - 1);
    }

    return [
      _TreeSectionHeader(type: type, parentCount: roots.length, total: total),
      const SizedBox(height: AffluenaSpacing.space3),
      ...rows,
    ];
  }
}
