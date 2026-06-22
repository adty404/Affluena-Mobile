import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../transactions/data/transaction_models.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/quick_entry_templates_controller.dart';
import '../data/quick_entry_models.dart';

class QuickEntryTemplatesScreen extends ConsumerStatefulWidget {
  const QuickEntryTemplatesScreen({super.key});

  static const path = '/quick-entry/templates';

  @override
  ConsumerState<QuickEntryTemplatesScreen> createState() =>
      _QuickEntryTemplatesScreenState();
}

class _QuickEntryTemplatesScreenState
    extends ConsumerState<QuickEntryTemplatesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickEntryTemplatesControllerProvider);
    final controller = ref.read(quickEntryTemplatesControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.templates.isEmpty) {
      return const _TemplatesLoading();
    }

    if (state.loadError != null && state.templates.isEmpty) {
      return _TemplatesError(onRetry: controller.load);
    }

    final normalizedQuery = _query.trim().toLowerCase();
    final visibleTemplates = state.templates
        .where((template) {
          if (normalizedQuery.isEmpty) return true;
          final haystack = [
            template.name,
            _typeLabel(template.type),
            state.walletName(template.walletId),
            state.walletName(template.toWalletId),
            state.categoryName(template.categoryId),
            state.tagNames(template.tagIds),
          ].join(' ').toLowerCase();
          return haystack.contains(normalizedQuery);
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
                  'Quick-entry templates',
                  style: textTheme.headlineMedium,
                ),
              ),
              IconButton.filledTonal(
                key: const Key('add-template-button'),
                tooltip: 'Add template',
                onPressed: state.isSaving
                    ? null
                    : () => _showTemplateForm(context, ref, state: state),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          Text(
            'Manage reusable shortcuts without slowing down manual quick entry.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          TextField(
            key: const Key('template-search-field'),
            autocorrect: false,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search templates',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          if (state.message != null || state.actionError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaCard(
              backgroundColor: state.message != null
                  ? context.affluenaColors.forestSoft
                  : context.affluenaColors.surfaceTintSoft,
              child: Text(state.message ?? state.actionError!),
            ),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Templates',
            actionLabel: '${visibleTemplates.length} shown',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (visibleTemplates.isEmpty)
            const _EmptyTemplateState()
          else
            for (final template in visibleTemplates) ...[
              _TemplateCard(
                template: template,
                state: state,
                onDetail: () =>
                    _showTemplateDetail(context, ref, state, template),
                onExecute: () => _showExecuteSheet(context, ref, template),
                onEdit: () => _showTemplateForm(
                  context,
                  ref,
                  state: state,
                  template: template,
                ),
                onDelete: () =>
                    _confirmDeleteTemplate(context, controller, template),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.state,
    required this.onDetail,
    required this.onExecute,
    required this.onEdit,
    required this.onDelete,
  });

  final QuickEntryTemplate template;
  final QuickEntryTemplatesState state;
  final VoidCallback onDetail;
  final VoidCallback onExecute;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final category = template.type == TransactionType.transfer
        ? 'Transfer'
        : state.categoryName(template.categoryId);
    final wallet = template.type == TransactionType.transfer
        ? '${state.walletName(template.walletId)} -> ${state.walletName(template.toWalletId)}'
        : state.walletName(template.walletId);
    final tags = state.tagNames(template.tagIds);

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    _typeIcon(template.type),
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
                    Text(template.name, style: textTheme.titleMedium),
                    const SizedBox(height: AffluenaSpacing.space1),
                    Text(
                      MoneyFormatter.idr(template.amountMinor),
                      style: textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                key: Key('template-menu-${template.id}'),
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
          const SizedBox(height: AffluenaSpacing.space3),
          _TemplateMetaRow(
            icon: Icons.account_balance_wallet_outlined,
            text: wallet,
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          _TemplateMetaRow(icon: Icons.category_outlined, text: category),
          const SizedBox(height: AffluenaSpacing.space2),
          _TemplateMetaRow(icon: Icons.sell_outlined, text: tags),
          const SizedBox(height: AffluenaSpacing.space4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: Key('template-detail-${template.id}'),
                  onPressed: onDetail,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: FilledButton.icon(
                  key: Key('execute-template-${template.id}'),
                  onPressed: onExecute,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Execute'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateMetaRow extends StatelessWidget {
  const _TemplateMetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.inkMuted),
        const SizedBox(width: AffluenaSpacing.space2),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _EmptyTemplateState extends StatelessWidget {
  const _EmptyTemplateState();

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
          Icon(Icons.bolt_outlined, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('No templates yet', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Create shortcuts for daily coffee, commute, salary, or transfers.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TemplatesLoading extends StatelessWidget {
  const _TemplatesLoading();

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
          Text('Quick-entry templates', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: SizedBox(
              height: 144,
              child: Center(child: Text('Loading templates')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatesError extends StatelessWidget {
  const _TemplatesError({required this.onRetry});

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
          Text('Templates unavailable', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load your quick-entry templates.'),
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

Future<void> _showTemplateDetail(
  BuildContext context,
  WidgetRef ref,
  QuickEntryTemplatesState state,
  QuickEntryTemplate template,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      final wallet = state.walletName(template.walletId);
      final category = template.type == TransactionType.transfer
          ? 'Transfer'
          : state.categoryName(template.categoryId);
      final tags = state.tagNames(template.tagIds);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AffluenaSpacing.space5,
            AffluenaSpacing.space2,
            AffluenaSpacing.space5,
            AffluenaSpacing.space5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${template.name} details', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              Text('Wallet: $wallet'),
              const SizedBox(height: AffluenaSpacing.space2),
              if (template.toWalletId != null) ...[
                Text('Destination: ${state.walletName(template.toWalletId)}'),
                const SizedBox(height: AffluenaSpacing.space2),
              ],
              Text('Category: $category'),
              const SizedBox(height: AffluenaSpacing.space2),
              Text('Tags: $tags'),
              const SizedBox(height: AffluenaSpacing.space2),
              Text('Amount: ${MoneyFormatter.idr(template.amountMinor)}'),
              if (template.note.isNotEmpty) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                Text('Note: ${template.note}'),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showExecuteSheet(context, ref, template);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Execute template'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showTemplateForm(
  BuildContext context,
  WidgetRef ref, {
  required QuickEntryTemplatesState state,
  QuickEntryTemplate? template,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) =>
        _TemplateFormSheet(initialState: state, template: template),
  );
}

class _TemplateFormSheet extends ConsumerStatefulWidget {
  const _TemplateFormSheet({required this.initialState, this.template});

  final QuickEntryTemplatesState initialState;
  final QuickEntryTemplate? template;

  @override
  ConsumerState<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends ConsumerState<_TemplateFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  String? _walletId;
  String? _toWalletId;
  String? _categoryId;
  String? _tagId;

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    _type = template?.type ?? TransactionType.expense;
    _walletId =
        template?.walletId ?? widget.initialState.wallets.firstOrNull?.id;
    _toWalletId = template?.toWalletId;
    _categoryId =
        template?.categoryId ??
        widget.initialState.categoriesFor(_type).firstOrNull?.id;
    _tagId = template?.tagIds.firstOrNull;
    _nameController = TextEditingController(text: template?.name ?? '');
    _amountController = TextEditingController(
      text: template?.amountMinor.toString() ?? '',
    );
    _noteController = TextEditingController(text: template?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickEntryTemplatesControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final selectedWallet = state.walletById(_walletId);
    final selectedToWallet = state.walletById(_toWalletId);
    final selectedCategory = state.categoryById(_categoryId);
    final selectedTag = state.tagById(_tagId);
    final categories = state.categoriesFor(_type);
    final canSave = _canSave(state);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space4,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isEditing ? 'Edit template' : 'Create template',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: AffluenaSpacing.space4),
                      TextField(
                        key: const Key('template-name-field'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.bolt_outlined),
                          labelText: 'Template name',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AffluenaSpacing.space3),
                      TextField(
                        key: const Key('template-amount-field'),
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.payments_outlined),
                          labelText: 'Amount',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AffluenaSpacing.space4),
                      Wrap(
                        spacing: AffluenaSpacing.space2,
                        runSpacing: AffluenaSpacing.space2,
                        children: [
                          for (final type in _templateTypes)
                            ChoiceChip(
                              label: Text(_typeLabel(type)),
                              selected: _type == type,
                              onSelected: state.isSaving
                                  ? null
                                  : (_) => setState(() {
                                      _type = type;
                                      if (_type == TransactionType.transfer) {
                                        _categoryId = null;
                                      } else if (_type ==
                                          TransactionType.adjustment) {
                                        _categoryId = null;
                                        _toWalletId = null;
                                      } else {
                                        _toWalletId = null;
                                        if (!categories.any(
                                          (category) =>
                                              category.id == _categoryId,
                                        )) {
                                          _categoryId = state
                                              .categoriesFor(type)
                                              .firstOrNull
                                              ?.id;
                                        }
                                      }
                                    }),
                            ),
                        ],
                      ),
                      const SizedBox(height: AffluenaSpacing.space3),
                      SelectorRow(
                        key: const Key('template-wallet-selector'),
                        label: 'Wallet',
                        value: selectedWallet?.name ?? 'Choose wallet',
                        icon: Icons.account_balance_wallet_outlined,
                        enabled: state.wallets.isNotEmpty && !state.isSaving,
                        onTap: state.wallets.isEmpty
                            ? null
                            : () => _selectWallet(state),
                      ),
                      if (_type == TransactionType.transfer) ...[
                        const Divider(height: 1),
                        SelectorRow(
                          key: const Key('template-to-wallet-selector'),
                          label: 'Destination wallet',
                          value:
                              selectedToWallet?.name ??
                              'Choose destination wallet',
                          icon: Icons.swap_horiz,
                          enabled: state.wallets.length > 1 && !state.isSaving,
                          onTap: state.wallets.length <= 1
                              ? null
                              : () => _selectToWallet(state),
                        ),
                      ],
                      if (_type == TransactionType.expense ||
                          _type == TransactionType.income) ...[
                        const Divider(height: 1),
                        SelectorRow(
                          key: const Key('template-category-selector'),
                          label: 'Category',
                          value: selectedCategory?.name ?? 'Choose category',
                          icon: Icons.category_outlined,
                          enabled: categories.isNotEmpty && !state.isSaving,
                          onTap: categories.isEmpty
                              ? null
                              : () => _selectCategory(state),
                        ),
                      ],
                      const Divider(height: 1),
                      SelectorRow(
                        key: const Key('template-tag-selector'),
                        label: 'Tags',
                        value: selectedTag == null
                            ? 'Optional'
                            : _tagLabel(selectedTag.name),
                        icon: Icons.sell_outlined,
                        enabled: state.tags.isNotEmpty && !state.isSaving,
                        onTap: state.tags.isEmpty
                            ? null
                            : () => _selectTag(state),
                      ),
                      const Divider(height: 1),
                      TextField(
                        key: const Key('template-note-field'),
                        controller: _noteController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.notes_outlined),
                          labelText: 'Default note',
                        ),
                      ),
                      const SizedBox(height: AffluenaSpacing.space5),
                    ],
                  ),
                ),
              ),
              if (state.actionError != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                Text(
                  state.actionError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space4),
              FilledButton(
                key: const Key('template-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Saving...' : 'Save template'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSave(QuickEntryTemplatesState state) {
    if (state.isSaving) return false;
    if (_nameController.text.trim().isEmpty) return false;
    if (_amountMinor <= 0) return false;
    if (_walletId == null) return false;
    if (_type == TransactionType.transfer) {
      return _toWalletId != null && _toWalletId != _walletId;
    }
    if (_type == TransactionType.expense || _type == TransactionType.income) {
      return _categoryId != null;
    }
    return true;
  }

  int get _amountMinor => _parseAmount(_amountController.text);

  Future<void> _selectWallet(QuickEntryTemplatesState state) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Template wallet',
      selectedValue: _walletId,
      options: [
        for (final wallet in state.wallets)
          LookupSelectorOption<String>(
            value: wallet.id,
            label: wallet.name,
            subtitle: _walletTypeLabel(wallet.type),
            icon: _walletIcon(wallet.type),
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      _walletId = selected;
      if (_toWalletId == selected) _toWalletId = null;
    });
  }

  Future<void> _selectToWallet(QuickEntryTemplatesState state) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Destination wallet',
      selectedValue: _toWalletId,
      options: [
        for (final wallet in state.wallets)
          if (wallet.id != _walletId)
            LookupSelectorOption<String>(
              value: wallet.id,
              label: wallet.name,
              subtitle: _walletTypeLabel(wallet.type),
              icon: _walletIcon(wallet.type),
            ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() => _toWalletId = selected);
  }

  Future<void> _selectCategory(QuickEntryTemplatesState state) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Template category',
      selectedValue: _categoryId,
      options: [
        for (final category in state.categoriesFor(_type))
          LookupSelectorOption<String>(
            value: category.id,
            label: category.name,
            subtitle: _categoryTypeLabel(category.type),
            icon: Icons.category_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() => _categoryId = selected);
  }

  Future<void> _selectTag(QuickEntryTemplatesState state) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Template tag',
      selectedValue: _tagId ?? '',
      options: [
        const LookupSelectorOption<String>(
          value: '',
          label: 'No tag',
          icon: Icons.block,
        ),
        for (final tag in state.tags)
          LookupSelectorOption<String>(
            value: tag.id,
            label: _tagLabel(tag.name),
            icon: Icons.sell_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() => _tagId = selected.isEmpty ? null : selected);
  }

  Future<void> _save() async {
    final saved = await ref
        .read(quickEntryTemplatesControllerProvider.notifier)
        .saveTemplate(
          template: widget.template,
          request: QuickEntryTemplateRequest(
            name: _nameController.text.trim(),
            type: _type,
            walletId: _walletId ?? '',
            toWalletId: _type == TransactionType.transfer ? _toWalletId : null,
            categoryId:
                _type == TransactionType.expense ||
                    _type == TransactionType.income
                ? _categoryId
                : null,
            amountMinor: _amountMinor,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            tagIds: _tagId == null ? const [] : [_tagId!],
          ),
        );
    if (!mounted) return;
    if (saved) Navigator.of(context).pop();
  }
}

Future<void> _showExecuteSheet(
  BuildContext context,
  WidgetRef ref,
  QuickEntryTemplate template,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _ExecuteTemplateSheet(template: template),
  );
}

class _ExecuteTemplateSheet extends ConsumerStatefulWidget {
  const _ExecuteTemplateSheet({required this.template});

  final QuickEntryTemplate template;

  @override
  ConsumerState<_ExecuteTemplateSheet> createState() =>
      _ExecuteTemplateSheetState();
}

class _ExecuteTemplateSheetState extends ConsumerState<_ExecuteTemplateSheet> {
  late final TextEditingController _dateController;
  late final TextEditingController _noteController;
  String? _localError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController = TextEditingController(
      text:
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
    _noteController = TextEditingController(text: widget.template.note);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickEntryTemplatesControllerProvider);
    final textTheme = Theme.of(context).textTheme;

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
                'Execute ${widget.template.name}',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                key: const Key('template-execute-date-field'),
                controller: _dateController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.today_outlined),
                  labelText: 'Execution date',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextField(
                key: const Key('template-execute-note-field'),
                controller: _noteController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  labelText: 'Override note',
                ),
              ),
              if (_localError != null || state.actionError != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                Text(
                  _localError ?? state.actionError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('template-execute-button'),
                onPressed: state.isSaving ? null : _execute,
                child: Text(
                  state.isSaving ? 'Executing...' : 'Execute template',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _execute() async {
    final transactionAt = _transactionAtFromDate(_dateController.text);
    if (transactionAt == null) {
      setState(() => _localError = 'Use YYYY-MM-DD for the execution date.');
      return;
    }
    setState(() => _localError = null);

    final executed = await ref
        .read(quickEntryTemplatesControllerProvider.notifier)
        .executeTemplate(
          widget.template,
          ExecuteQuickEntryRequest(
            transactionAt: transactionAt,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          ),
        );
    if (!mounted) return;
    if (executed) Navigator.of(context).pop();
  }
}

Future<void> _confirmDeleteTemplate(
  BuildContext context,
  QuickEntryTemplatesController controller,
  QuickEntryTemplate template,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete template?'),
      content: Text('Delete ${template.name} from quick-entry templates?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete template'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deleteTemplate(template);
  }
}

int _parseAmount(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

String? _transactionAtFromDate(String value) {
  final trimmed = value.trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) return null;
  final parsed = DateTime.tryParse('${trimmed}T12:00:00');
  return parsed?.toUtc().toIso8601String();
}

String _typeLabel(TransactionType type) {
  return switch (type) {
    TransactionType.expense => 'Expense',
    TransactionType.income => 'Income',
    TransactionType.transfer => 'Transfer',
    TransactionType.adjustment => 'Adjustment',
  };
}

IconData _typeIcon(TransactionType type) {
  return switch (type) {
    TransactionType.expense => Icons.trending_down,
    TransactionType.income => Icons.trending_up,
    TransactionType.transfer => Icons.swap_horiz,
    TransactionType.adjustment => Icons.tune,
  };
}

String _categoryTypeLabel(CategoryType type) {
  return switch (type) {
    CategoryType.expense => 'Expense',
    CategoryType.income => 'Income',
  };
}

String _tagLabel(String name) {
  final normalized = name.trim().replaceFirst(RegExp(r'^#+'), '');
  return normalized.isEmpty ? '#' : '#$normalized';
}

String _walletTypeLabel(WalletType type) {
  return switch (type) {
    WalletType.cash => 'Cash',
    WalletType.bank => 'Bank',
    WalletType.eWallet => 'E-wallet',
    WalletType.investment => 'Investment',
    WalletType.goal => 'Goal',
  };
}

IconData _walletIcon(WalletType type) {
  return switch (type) {
    WalletType.cash => Icons.payments_outlined,
    WalletType.bank => Icons.account_balance_outlined,
    WalletType.eWallet => Icons.phone_iphone_outlined,
    WalletType.investment => Icons.trending_up,
    WalletType.goal => Icons.flag_outlined,
  };
}

const _templateTypes = [
  TransactionType.expense,
  TransactionType.income,
  TransactionType.transfer,
  TransactionType.adjustment,
];
