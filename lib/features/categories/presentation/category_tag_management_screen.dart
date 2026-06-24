import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../../tags/data/tag_models.dart';
import '../application/category_tag_management_controller.dart';
import '../data/category_models.dart';

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
    final visibleTags = state.tags
        .where((tag) {
          if (normalizedQuery.isEmpty) return true;
          return tagLabel(tag.name).toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    return DrillInScaffold(
      title: 'Categories & Tags',
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
        IconButton.filledTonal(
          key: const Key('add-tag-button'),
          tooltip: 'Add tag',
          onPressed: state.isSaving ? null : () => _showTagForm(context),
          icon: const Icon(Icons.label_outline),
        ),
        const SizedBox(width: AffluenaSpacing.space2),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          TextField(
            key: const Key('category-tag-search-field'),
            autocorrect: false,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search categories and tags',
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
            AffluenaBanner.error(
              state.actionError!,
              onRetry: controller.load,
            ),
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
          const SizedBox(height: AffluenaSpacing.space5),
          SectionHeader(
            title: 'Tags',
            actionLabel: '${visibleTags.length} shown',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (visibleTags.isEmpty)
            _EmptyManagementState(
              icon: Icons.label_outline,
              title: normalizedQuery.isEmpty ? 'No tags yet' : 'No tags match',
              message: normalizedQuery.isEmpty
                  ? 'Tags label transactions across categories. Create your first tag.'
                  : 'Try a different search to find a tag.',
              actionLabel: normalizedQuery.isEmpty ? 'Add tag' : null,
              onAction: normalizedQuery.isEmpty
                  ? () => _showTagForm(context)
                  : null,
            )
          else ...[
            for (final tag in visibleTags) ...[
              _TagCard(
                tag: tag,
                onEdit: () => _showTagForm(context, tag: tag),
                onDelete: () => _confirmDeleteTag(context, controller, tag),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
            if (state.hasMoreTags && normalizedQuery.isEmpty) ...[
              const SizedBox(height: AffluenaSpacing.space2),
              OutlinedButton(
                key: const Key('tag-load-more-button'),
                onPressed: state.isLoadingMoreTags
                    ? null
                    : controller.loadMoreTags,
                child: Text(
                  state.isLoadingMoreTags
                      ? 'Loading...'
                      : 'Load more (${state.tags.length} of ${state.tagTotal})',
                ),
              ),
            ],
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
      final key =
          (category.parentId != null && ids.contains(category.parentId))
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
          onEdit: () => _showCategoryForm(
            context,
            ref,
            state: state,
            category: category,
          ),
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
      _TreeSectionHeader(
        type: type,
        parentCount: roots.length,
        total: total,
      ),
      const SizedBox(height: AffluenaSpacing.space3),
      ...rows,
    ];
  }
}

class _TreeSectionHeader extends StatelessWidget {
  const _TreeSectionHeader({
    required this.type,
    required this.parentCount,
    required this.total,
  });

  final CategoryType type;
  final int parentCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final textTheme = Theme.of(context).textTheme;
    final isIncome = type == CategoryType.income;
    final accent = isIncome ? colors.success : colors.inkMuted;
    final parentLabel = parentCount == 1 ? '1 parent' : '$parentCount parents';
    final totalLabel = total == 1 ? '1 total' : '$total total';

    return Padding(
      padding: const EdgeInsets.only(bottom: AffluenaSpacing.space1),
      child: Row(
        children: [
          Icon(
            isIncome ? Icons.trending_up : Icons.trending_down,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: AffluenaSpacing.space2),
          Text(type.label, style: textTheme.titleSmall),
          const SizedBox(width: AffluenaSpacing.space2),
          Expanded(
            child: Text(
              '$parentLabel · $totalLabel',
              style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single row in the category hierarchy tree. Draws connector guides to the
/// left (a vertical trunk + an elbow into the row) so parent -> child ->
/// grandchild reads as a branching tree, with a leading icon, the name, a
/// child-count hint, a type badge, a collapse chevron, and inline actions.
class _CategoryTreeNode extends StatelessWidget {
  const _CategoryTreeNode({
    required this.category,
    required this.depth,
    required this.isLast,
    required this.hasChildren,
    required this.childCount,
    required this.collapsed,
    required this.showConnectors,
    required this.parentName,
    required this.canAddChild,
    required this.onToggle,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final int depth;
  final bool isLast;
  final bool hasChildren;
  final int childCount;
  final bool collapsed;
  final bool showConnectors;
  final String parentName;
  final bool canAddChild;
  final VoidCallback? onToggle;
  final VoidCallback? onAddChild;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const double _indentWidth = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;

    // IntrinsicHeight bounds the Row's height to the card so the stretched
    // connector slots can paint full-height guides without unbounded
    // constraints inside the scrolling list.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showConnectors)
            ..._buildConnectors(colors)
          else if (depth > 0)
            SizedBox(width: _indentWidth * depth),
          Expanded(child: _buildCard(context)),
        ],
      ),
    );
  }

  /// Builds one indent slot per ancestor level. Levels above this node show a
  /// continuing vertical trunk; the node's own level shows an elbow branch.
  List<Widget> _buildConnectors(AffluenaSemanticColors colors) {
    final line = colors.borderSubtle;
    final slots = <Widget>[];
    // Ancestor trunks (every level except the node's own).
    for (var i = 0; i < depth - 1; i++) {
      slots.add(
        SizedBox(
          width: _indentWidth,
          child: Center(
            child: Container(width: 1.5, color: line),
          ),
        ),
      );
    }
    // The node's own elbow: a half-height trunk (full when not last) plus the
    // horizontal branch into the row.
    slots.add(
      SizedBox(
        width: _indentWidth,
        child: CustomPaint(
          painter: _ElbowPainter(color: line, isLast: isLast),
        ),
      ),
    );
    return slots;
  }

  Widget _buildCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final isRoot = depth == 0;
    final isIncome = category.type == CategoryType.income;

    final chevron = hasChildren
        ? IconButton(
            key: Key('category-toggle-${category.id}'),
            tooltip: collapsed ? 'Expand' : 'Collapse',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            iconSize: 20,
            onPressed: onToggle,
            icon: Icon(
              collapsed ? Icons.chevron_right : Icons.expand_more,
              color: colors.inkMuted,
            ),
          )
        : const SizedBox(width: 32);

    return AffluenaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AffluenaSpacing.space3,
        vertical: AffluenaSpacing.space3,
      ),
      child: Row(
        children: [
          chevron,
          DecoratedBox(
            decoration: BoxDecoration(
              color: isRoot ? colors.forestSoft : colors.surfaceTintSoft,
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AffluenaSpacing.space2),
              child: Icon(
                isRoot
                    ? Icons.folder_outlined
                    : Icons.subdirectory_arrow_right,
                color: isRoot ? colors.forest : colors.inkMuted,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        category.name,
                        style: textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasChildren) ...[
                      const SizedBox(width: AffluenaSpacing.space2),
                      Text(
                        '$childCount sub',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                StatusBadge(
                  label: category.type.label,
                  tone: isIncome ? StatusTone.success : StatusTone.neutral,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            key: Key('category-menu-${category.id}'),
            tooltip: 'Category actions',
            onSelected: (value) {
              switch (value) {
                case 'add':
                  onAddChild?.call();
                case 'edit':
                  onEdit();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (context) => [
              if (canAddChild && onAddChild != null)
                const PopupMenuItem(
                  value: 'add',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.add),
                    title: Text('Add subcategory'),
                  ),
                ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints the elbow connector for a child row: a vertical trunk segment that
/// stops at the row's vertical center (full-height when the node has following
/// siblings) and a horizontal branch reaching toward the card.
class _ElbowPainter extends CustomPainter {
  const _ElbowPainter({required this.color, required this.isLast});

  final Color color;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    // Vertical trunk from the top; stops at center for the last child so the
    // line doesn't dangle past the final branch.
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, isLast ? centerY : size.height),
      paint,
    );
    // Horizontal branch into the row.
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(size.width, centerY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ElbowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isLast != isLast;
}

class _TagCard extends StatelessWidget {
  const _TagCard({
    required this.tag,
    required this.onEdit,
    required this.onDelete,
  });

  final Tag tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceTintSoft,
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AffluenaSpacing.space2),
              child: Icon(Icons.label_outline, color: colors.forest, size: 18),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Text(tagLabel(tag.name), style: textTheme.titleMedium),
          ),
          PopupMenuButton<String>(
            key: Key('tag-menu-${tag.id}'),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyManagementState extends StatelessWidget {
  const _EmptyManagementState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      backgroundColor: colors.forestSoft,
      borderColor: colors.forestSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(message, style: textTheme.bodySmall),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTagLoading extends StatelessWidget {
  const _CategoryTagLoading();

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Categories & Tags',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          const AffluenaSkeleton(height: 56, radius: AffluenaRadii.control),
          const SizedBox(height: AffluenaSpacing.space5),
          for (var i = 0; i < 4; i++) ...[
            const AffluenaCard(child: _ManagementRowSkeleton()),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
        ],
      ),
    );
  }
}

class _ManagementRowSkeleton extends StatelessWidget {
  const _ManagementRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AffluenaSkeleton(width: 34, height: 34),
        SizedBox(width: AffluenaSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AffluenaSkeleton.line(width: 140, height: 14),
              SizedBox(height: AffluenaSpacing.space2),
              AffluenaSkeleton.line(width: 90),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTagError extends StatelessWidget {
  const _CategoryTagError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Categories & Tags',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          AffluenaBanner.error(
            'We could not load your categories and tags.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

Future<void> _showCategoryForm(
  BuildContext context,
  WidgetRef ref, {
  required CategoryTagManagementState state,
  Category? category,
  Category? presetParent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _CategoryFormSheet(
      initialState: state,
      category: category,
      presetParent: presetParent,
    ),
  );
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({
    required this.initialState,
    this.category,
    this.presetParent,
  });

  final CategoryTagManagementState initialState;
  final Category? category;

  /// When opening "Add subcategory" from a node, the form pre-selects this
  /// parent and adopts its type so the new child lands in the right branch.
  final Category? presetParent;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  late CategoryType _type;
  Category? _parent;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _type =
        widget.category?.type ??
        widget.presetParent?.type ??
        CategoryType.expense;
    if (widget.category?.parentId != null) {
      _parent = widget.initialState.categoryById(widget.category!.parentId!);
    } else if (widget.category == null && widget.presetParent != null) {
      _parent = widget.presetParent;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryTagManagementControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final parentOptions = _parentOptions(state);
    final selectedParent = _selectedParent(parentOptions);
    final canSave = _nameController.text.trim().isNotEmpty && !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit category' : 'Create category',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                key: const Key('category-name-field'),
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                  labelText: 'Category name',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(
                    value: CategoryType.expense,
                    icon: Icon(Icons.trending_down),
                    label: Text('Expense'),
                  ),
                  ButtonSegment(
                    value: CategoryType.income,
                    icon: Icon(Icons.trending_up),
                    label: Text('Income'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: state.isSaving
                    ? null
                    : (selection) {
                        setState(() {
                          _type = selection.single;
                          if (_parent?.type != _type) _parent = null;
                        });
                      },
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              SelectorRow(
                label: 'Parent category',
                value: selectedParent?.name ?? 'No parent',
                icon: Icons.account_tree_outlined,
                enabled: !state.isSaving,
                onTap: () => _selectParent(parentOptions, selectedParent),
              ),
              const SizedBox(height: AffluenaSpacing.space1),
              Text(
                'Categories nest up to 3 levels. Only categories with room for a child are shown.',
                style: textTheme.bodySmall?.copyWith(
                  color: context.affluenaColors.inkMuted,
                ),
              ),
              if (state.actionError != null) ...[
                const SizedBox(height: AffluenaSpacing.space4),
                AffluenaBanner.error(state.actionError!),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('category-save-button'),
                onPressed: canSave ? () => _save(selectedParent) : null,
                child: Text(state.isSaving ? 'Saving...' : 'Save category'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Category> _parentOptions(CategoryTagManagementState state) {
    return state.categories
        .where(
          (category) =>
              category.type == _type &&
              category.id != widget.category?.id &&
              // Enforce the 3-level hierarchy client-side: a category already at
              // the deepest allowed level cannot accept new children.
              state.canParent(category),
        )
        .toList(growable: false);
  }

  Category? _selectedParent(List<Category> options) {
    final parentId = _parent?.id;
    if (parentId == null) return null;
    for (final category in options) {
      if (category.id == parentId) return category;
    }
    return null;
  }

  Future<void> _selectParent(
    List<Category> options,
    Category? selectedParent,
  ) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Parent category',
      selectedValue: selectedParent?.id ?? '',
      options: [
        const LookupSelectorOption<String>(
          value: '',
          label: 'No parent',
          icon: Icons.block,
        ),
        for (final category in options)
          LookupSelectorOption<String>(
            value: category.id,
            label: category.name,
            subtitle: category.type.label,
            icon: Icons.category_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (selected.isEmpty) {
        _parent = null;
        return;
      }
      for (final category in options) {
        if (category.id == selected) {
          _parent = category;
          break;
        }
      }
    });
  }

  Future<void> _save(Category? selectedParent) async {
    final saved = await ref
        .read(categoryTagManagementControllerProvider.notifier)
        .saveCategory(
          category: widget.category,
          name: _nameController.text,
          type: _type,
          parentId: selectedParent?.id,
        );
    if (!mounted) return;
    if (saved) Navigator.of(context).pop();
  }
}

Future<void> _showTagForm(BuildContext context, {Tag? tag}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _TagFormSheet(tag: tag),
  );
}

class _TagFormSheet extends ConsumerStatefulWidget {
  const _TagFormSheet({this.tag});

  final Tag? tag;

  @override
  ConsumerState<_TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends ConsumerState<_TagFormSheet> {
  late final TextEditingController _nameController;

  bool get _isEditing => widget.tag != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.tag == null ? '' : normalizedTagName(widget.tag!.name),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryTagManagementControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final canSave = _nameController.text.trim().isNotEmpty && !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit tag' : 'Create tag',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                key: const Key('tag-name-field'),
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.label_outline),
                  labelText: 'Tag name',
                  prefixText: '#',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (state.actionError != null) ...[
                const SizedBox(height: AffluenaSpacing.space4),
                AffluenaBanner.error(state.actionError!),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('tag-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Saving...' : 'Save tag'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final saved = await ref
        .read(categoryTagManagementControllerProvider.notifier)
        .saveTag(
          tag: widget.tag,
          name: normalizedTagName(_nameController.text),
        );
    if (!mounted) return;
    if (saved) Navigator.of(context).pop();
  }
}

Future<void> _confirmDeleteCategory(
  BuildContext context,
  CategoryTagManagementController controller,
  Category category,
) async {
  final colors = context.affluenaColors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete category?'),
      content: Text('Delete ${category.name} from your category hierarchy?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.coral),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete category'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deleteCategory(category);
  }
}

Future<void> _confirmDeleteTag(
  BuildContext context,
  CategoryTagManagementController controller,
  Tag tag,
) async {
  final colors = context.affluenaColors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete tag?'),
      content: Text(
        'Delete ${tagLabel(tag.name)} from your transaction labels?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.coral),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete tag'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deleteTag(tag);
  }
}

String tagLabel(String name) {
  final normalized = normalizedTagName(name);
  return normalized.isEmpty ? '#' : '#$normalized';
}

String normalizedTagName(String name) {
  return name.trim().replaceFirst(RegExp(r'^#+'), '');
}
