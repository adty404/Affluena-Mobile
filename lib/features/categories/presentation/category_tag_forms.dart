part of 'category_tag_management_screen.dart';

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
    final selected = await showCategoryTreePicker(
      context: context,
      title: 'Parent category',
      selectedId: selectedParent?.id,
      allowNone: true,
      noneLabel: 'No parent',
      categories: [
        for (final category in options)
          CategoryTreeEntry(
            id: category.id,
            name: category.name,
            parentId: category.parentId,
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
