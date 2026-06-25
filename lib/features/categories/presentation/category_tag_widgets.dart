part of 'category_tag_management_screen.dart';

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
          child: Center(child: Container(width: 1.5, color: line)),
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
                isRoot ? Icons.folder_outlined : Icons.subdirectory_arrow_right,
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
        padding: AffluenaInsets.screen,
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
        padding: AffluenaInsets.screen,
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
