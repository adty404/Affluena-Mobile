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
                _isEditing ? 'Ubah kategori' : 'Buat kategori',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                key: const Key('category-name-field'),
                controller: _nameController,
                // The next control is a segmented button/picker that never
                // receives keyboard focus, so "next" would strand the focus.
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                  labelText: 'Nama kategori',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(
                    value: CategoryType.expense,
                    icon: Icon(Icons.trending_down),
                    label: Text('Pengeluaran'),
                  ),
                  ButtonSegment(
                    value: CategoryType.income,
                    icon: Icon(Icons.trending_up),
                    label: Text('Pemasukan'),
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
                label: 'Kategori induk',
                value: selectedParent?.name ?? 'Tanpa induk',
                icon: Icons.account_tree_outlined,
                enabled: !state.isSaving,
                onTap: () => _selectParent(parentOptions, selectedParent),
              ),
              const SizedBox(height: AffluenaSpacing.space1),
              Text(
                'Kategori bisa bertingkat hingga 3 level. Hanya kategori yang masih bisa menampung subkategori yang ditampilkan.',
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
                child: Text(
                  state.isSaving ? 'Menyimpan...' : 'Simpan kategori',
                ),
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
      title: 'Kategori induk',
      selectedId: selectedParent?.id,
      allowNone: true,
      noneLabel: 'Tanpa induk',
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

Future<void> _confirmDeleteCategory(
  BuildContext context,
  CategoryTagManagementController controller,
  Category category,
) async {
  final confirmed = await skyConfirm(
    context,
    title: 'Hapus kategori?',
    message: 'Hapus ${category.name} dari hierarki kategori kamu?',
    confirmLabel: 'Hapus kategori',
  );
  if (confirmed) {
    await controller.deleteCategory(category);
  }
}
