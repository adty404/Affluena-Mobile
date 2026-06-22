import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryTagManagementControllerProvider);
    final controller = ref.read(
      categoryTagManagementControllerProvider.notifier,
    );
    final textTheme = Theme.of(context).textTheme;

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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Categories & Tags',
                  style: textTheme.headlineMedium,
                ),
              ),
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
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space4),
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
            AffluenaCard(
              backgroundColor: context.affluenaColors.surfaceTintSoft,
              child: Text(state.actionError!),
            ),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Categories',
            actionLabel: '${visibleCategories.length} shown',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (visibleCategories.isEmpty)
            const _EmptyManagementState(
              icon: Icons.account_tree_outlined,
              title: 'No categories found',
              message: 'Create income or expense categories for transactions.',
            )
          else
            for (final category in visibleCategories) ...[
              _CategoryCard(
                category: category,
                parentName: state.categoryName(category.parentId),
                onEdit: () => _showCategoryForm(
                  context,
                  ref,
                  state: state,
                  category: category,
                ),
                onDelete: () =>
                    _confirmDeleteCategory(context, controller, category),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
          const SizedBox(height: AffluenaSpacing.space5),
          SectionHeader(
            title: 'Tags',
            actionLabel: '${visibleTags.length} shown',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (visibleTags.isEmpty)
            const _EmptyManagementState(
              icon: Icons.label_outline,
              title: 'No tags found',
              message: 'Create labels to group transactions across categories.',
            )
          else
            for (final tag in visibleTags) ...[
              _TagCard(
                tag: tag,
                onEdit: () => _showTagForm(context, tag: tag),
                onDelete: () => _confirmDeleteTag(context, controller, tag),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.parentName,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final String parentName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final typeLabel = category.type == CategoryType.expense
        ? 'Expense'
        : 'Income';
    final parentLabel = category.parentId == null
        ? 'Root category'
        : 'Parent: $parentName';

    return AffluenaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.forestSoft,
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AffluenaSpacing.space2),
              child: Icon(
                category.parentId == null
                    ? Icons.category_outlined
                    : Icons.subdirectory_arrow_right,
                color: colors.forest,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: textTheme.titleMedium),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(parentLabel, style: textTheme.bodySmall),
                const SizedBox(height: AffluenaSpacing.space2),
                _StatusChip(label: typeLabel),
              ],
            ),
          ),
          PopupMenuButton<String>(
            key: Key('category-menu-${category.id}'),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.forestSoft,
        borderRadius: BorderRadius.circular(AffluenaRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space2,
          vertical: AffluenaSpacing.space1,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyManagementState extends StatelessWidget {
  const _EmptyManagementState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

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
        ],
      ),
    );
  }
}

class _CategoryTagLoading extends StatelessWidget {
  const _CategoryTagLoading();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Categories & Tags', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: SizedBox(
              height: 144,
              child: Center(child: Text('Loading categories and tags')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTagError extends StatelessWidget {
  const _CategoryTagError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text(
            'Categories & tags unavailable',
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load your categories and tags.'),
                const SizedBox(height: AffluenaSpacing.space4),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
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
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) =>
        _CategoryFormSheet(initialState: state, category: category),
  );
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({required this.initialState, this.category});

  final CategoryTagManagementState initialState;
  final Category? category;

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
    _type = widget.category?.type ?? CategoryType.expense;
    if (widget.category?.parentId != null) {
      _parent = widget.initialState.categoryById(widget.category!.parentId!);
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
    final parentOptions = _parentOptions(state.categories);
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
              if (state.actionError != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                Text(
                  state.actionError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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

  List<Category> _parentOptions(List<Category> categories) {
    return categories
        .where(
          (category) =>
              category.type == _type && category.id != widget.category?.id,
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
            subtitle: category.type.apiValue,
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
                const SizedBox(height: AffluenaSpacing.space3),
                Text(
                  state.actionError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
