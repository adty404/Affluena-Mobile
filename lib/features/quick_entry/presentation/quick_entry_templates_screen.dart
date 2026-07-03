import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../../core/formatters/tag_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_chip_bar.dart';
import '../../shared/presentation/widgets/affluena_choice_chip.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/date_picker_field.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../../transactions/data/transaction_models.dart';
import '../../wallets/presentation/wallet_format.dart';
import '../application/quick_entry_templates_controller.dart';
import '../data/quick_entry_models.dart';
import 'tag_multi_select_sheet.dart';

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

    return DrillInScaffold(
      title: 'Template catat cepat',
      actions: [
        IconButton.filledTonal(
          key: const Key('add-template-button'),
          tooltip: 'Tambah template',
          onPressed: state.isSaving
              ? null
              : () => _showTemplateForm(context, ref, state: state),
          icon: const Icon(Icons.add),
        ),
      ],
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          Text(
            'Kelola pintasan yang bisa dipakai ulang tanpa memperlambat catat '
            'cepat manual.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          TextField(
            key: const Key('template-search-field'),
            autocorrect: false,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Cari template',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          if (state.actionError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner.error(
              state.actionError!,
              onRetry: state.isSaving ? null : controller.load,
            ),
          ] else if (state.message != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner.success(
              state.message!,
              onDismiss: controller.clearMessage,
            ),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Template tersimpan',
            actionLabel: '${visibleTemplates.length} ditampilkan',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (visibleTemplates.isEmpty)
            state.templates.isEmpty
                ? _EmptyTemplateState(
                    onCreate: state.isSaving
                        ? null
                        : () => _showTemplateForm(context, ref, state: state),
                  )
                : const _NoSearchResults()
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
                  PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
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
                  label: const Text('Detail'),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: FilledButton.icon(
                  key: Key('execute-template-${template.id}'),
                  onPressed: onExecute,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Jalankan'),
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
  const _EmptyTemplateState({this.onCreate});

  final VoidCallback? onCreate;

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
          Text('Belum ada template', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Template mengubah transaksi berulang — kopi harian, ongkos, '
            'gaji, transfer rutin — jadi entri satu ketukan.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          FilledButton.icon(
            key: const Key('empty-create-template-button'),
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Buat template pertamamu'),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.search_off_outlined, color: colors.inkMuted),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('Tidak ada template yang cocok', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Coba nama, dompet, kategori, atau tag yang lain.',
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
    return DrillInScaffold(
      title: 'Template catat cepat',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          Text(
            'Kelola pintasan yang bisa dipakai ulang tanpa memperlambat catat '
            'cepat manual.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaSkeleton(height: 56, radius: AffluenaRadii.control),
          const SizedBox(height: AffluenaSpacing.space6),
          const AffluenaSkeleton.line(width: 120, height: 16),
          const SizedBox(height: AffluenaSpacing.space3),
          for (var i = 0; i < 3; i++) ...[
            const _TemplateCardSkeleton(),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
        ],
      ),
    );
  }
}

class _TemplateCardSkeleton extends StatelessWidget {
  const _TemplateCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AffluenaSkeleton(width: 34, height: 34),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AffluenaSkeleton.line(width: 140, height: 14),
                    SizedBox(height: AffluenaSpacing.space2),
                    AffluenaSkeleton.line(width: 100, height: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          const AffluenaSkeleton.line(width: 180, height: 12),
          const SizedBox(height: AffluenaSpacing.space2),
          const AffluenaSkeleton.line(width: 140, height: 12),
          const SizedBox(height: AffluenaSpacing.space4),
          Row(
            children: const [
              Expanded(child: AffluenaSkeleton(height: 40, radius: 18)),
              SizedBox(width: AffluenaSpacing.space3),
              Expanded(child: AffluenaSkeleton(height: 40, radius: 18)),
            ],
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
    return DrillInScaffold(
      title: 'Template catat cepat',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          AffluenaBanner.error(
            'Kami tidak bisa memuat template catat cepat kamu.',
            onRetry: onRetry,
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
        child: SingleChildScrollView(
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
              Text('Rincian ${template.name}', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              SkyDetailCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SkyDetailRow(label: 'Dompet', value: wallet),
                    if (template.toWalletId != null) ...[
                      const SizedBox(height: AffluenaSpacing.space3),
                      SkyDetailRow(
                        label: 'Tujuan',
                        value: state.walletName(template.toWalletId),
                      ),
                    ],
                    const SizedBox(height: AffluenaSpacing.space3),
                    SkyDetailRow(label: 'Kategori', value: category),
                    const SizedBox(height: AffluenaSpacing.space3),
                    SkyDetailRow(label: 'Tag', value: tags),
                    const SizedBox(height: AffluenaSpacing.space3),
                    SkyDetailRow(
                      label: 'Jumlah',
                      value: MoneyFormatter.idr(template.amountMinor),
                    ),
                    if (template.note.isNotEmpty) ...[
                      const SizedBox(height: AffluenaSpacing.space3),
                      SkyDetailRow(label: 'Catatan', value: template.note),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showExecuteSheet(context, ref, template);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Jalankan template'),
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
  late final TextEditingController _noteController;
  // Focus target for the amount field so the name field's "next" action lands
  // somewhere instead of stranding the keyboard focus.
  final _amountFocus = FocusNode();
  late TransactionType _type;
  late int _amountMinor;
  String? _walletId;
  String? _toWalletId;
  String? _categoryId;
  late List<String> _tagIds;

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
    _tagIds = List<String>.from(template?.tagIds ?? const []);
    _amountMinor = template?.amountMinor ?? 0;
    _nameController = TextEditingController(text: template?.name ?? '');
    _noteController = TextEditingController(text: template?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickEntryTemplatesControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final selectedWallet = state.walletById(_walletId);
    final selectedToWallet = state.walletById(_toWalletId);
    final selectedCategory = state.categoryById(_categoryId);
    final selectedTags = [for (final id in _tagIds) ?state.tagById(id)];
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
                        _isEditing ? 'Ubah template' : 'Buat template',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: AffluenaSpacing.space4),
                      TextField(
                        key: const Key('template-name-field'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _amountFocus.requestFocus(),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.bolt_outlined),
                          labelText: 'Nama template',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AffluenaSpacing.space3),
                      MoneyInput(
                        key: const Key('template-amount-field'),
                        label: 'Jumlah',
                        initialValue: _amountMinor,
                        enabled: !state.isSaving,
                        focusNode: _amountFocus,
                        onChanged: (value) =>
                            setState(() => _amountMinor = value ?? 0),
                      ),
                      const SizedBox(height: AffluenaSpacing.space4),
                      AffluenaChipBar(
                        chips: [
                          for (final type in _templateTypes)
                            AffluenaChoiceChip(
                              label: _typeLabel(type),
                              selected: _type == type,
                              onSelected: state.isSaving
                                  ? null
                                  : () => setState(() {
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
                        label: 'Dompet',
                        value: selectedWallet?.name ?? 'Pilih dompet',
                        isPlaceholder: selectedWallet == null,
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
                          label: 'Dompet tujuan',
                          value:
                              selectedToWallet?.name ?? 'Pilih dompet tujuan',
                          isPlaceholder: selectedToWallet == null,
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
                          label: 'Kategori',
                          value: selectedCategory?.name ?? 'Pilih kategori',
                          isPlaceholder: selectedCategory == null,
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
                        label: 'Tag',
                        // Matches the list rows' empty label ('Tanpa tag')
                        // instead of the inconsistent 'Opsional'.
                        value: selectedTags.isEmpty
                            ? 'Tanpa tag'
                            : selectedTags
                                  .map((tag) => tagLabel(tag.name))
                                  .join(', '),
                        icon: Icons.sell_outlined,
                        enabled: state.tags.isNotEmpty && !state.isSaving,
                        onTap: state.tags.isEmpty
                            ? null
                            : () => _selectTags(state),
                      ),
                      if (selectedTags.isNotEmpty) ...[
                        const SizedBox(height: AffluenaSpacing.space2),
                        Wrap(
                          spacing: AffluenaSpacing.space2,
                          runSpacing: AffluenaSpacing.space2,
                          children: [
                            for (final tag in selectedTags)
                              StatusBadge(
                                label: tagLabel(tag.name),
                                tone: StatusTone.neutral,
                              ),
                          ],
                        ),
                      ],
                      const Divider(height: 1),
                      TextField(
                        key: const Key('template-note-field'),
                        controller: _noteController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.notes_outlined),
                          labelText: 'Catatan bawaan',
                        ),
                      ),
                      const SizedBox(height: AffluenaSpacing.space5),
                    ],
                  ),
                ),
              ),
              if (state.actionError != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                AffluenaBanner.error(state.actionError!),
              ],
              const SizedBox(height: AffluenaSpacing.space4),
              FilledButton(
                key: const Key('template-save-button'),
                onPressed: canSave ? _save : null,
                child: state.isSaving
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AffluenaSpacing.space2),
                          Text('Menyimpan...'),
                        ],
                      )
                    : const Text('Simpan template'),
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

  Future<void> _selectWallet(QuickEntryTemplatesState state) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Dompet template',
      searchHint: 'Cari dompet',
      selectedValue: _walletId,
      options: [
        for (final wallet in state.wallets)
          LookupSelectorOption<String>(
            value: wallet.id,
            label: wallet.name,
            subtitle: walletTypeLabel(wallet.type),
            icon: walletIcon(wallet.type),
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
      title: 'Dompet tujuan',
      searchHint: 'Cari dompet',
      selectedValue: _toWalletId,
      options: [
        for (final wallet in state.wallets)
          if (wallet.id != _walletId)
            LookupSelectorOption<String>(
              value: wallet.id,
              label: wallet.name,
              subtitle: walletTypeLabel(wallet.type),
              icon: walletIcon(wallet.type),
            ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() => _toWalletId = selected);
  }

  Future<void> _selectCategory(QuickEntryTemplatesState state) async {
    final selected = await showCategoryTreePicker(
      context: context,
      title: 'Kategori template',
      selectedId: _categoryId,
      quickAdd: CategoryQuickAdd(
        type: _type == TransactionType.income
            ? CategoryType.income
            : CategoryType.expense,
      ),
      onMutated: () =>
          ref.read(quickEntryTemplatesControllerProvider.notifier).load(),
      categories: [
        for (final category in state.categoriesFor(_type))
          CategoryTreeEntry.fromCategory(category),
      ],
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    setState(() => _categoryId = selected);
  }

  Future<void> _selectTags(QuickEntryTemplatesState state) async {
    final selected = await showTagMultiSelectSheet(
      context: context,
      tags: state.tags,
      selectedIds: _tagIds,
    );
    if (!mounted || selected == null) return;
    setState(() => _tagIds = selected);
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
            tagIds: _tagIds,
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
  late final TextEditingController _noteController;
  late DateTime _executionDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _executionDate = DateTime(now.year, now.month, now.day);
    _noteController = TextEditingController(text: widget.template.note);
  }

  @override
  void dispose() {
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
                'Jalankan ${widget.template.name}',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              DatePickerField(
                key: const Key('template-execute-date-field'),
                label: 'Tanggal pelaksanaan',
                value: _executionDate,
                icon: Icons.today_outlined,
                lastDate: DateTime.now(),
                enabled: !state.isSaving,
                onChanged: (picked) => setState(() => _executionDate = picked),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextField(
                key: const Key('template-execute-note-field'),
                controller: _noteController,
                enabled: !state.isSaving,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  labelText: 'Ganti catatan',
                ),
              ),
              if (state.actionError != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                AffluenaBanner.error(state.actionError!),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('template-execute-button'),
                onPressed: state.isSaving ? null : _execute,
                child: Text(
                  state.isSaving ? 'Menjalankan...' : 'Jalankan template',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _execute() async {
    final transactionAt = _transactionAtFromDate(_executionDate);

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
  final confirmed = await skyConfirm(
    context,
    title: 'Hapus template?',
    message: 'Hapus ${template.name} dari template catat cepat?',
    confirmLabel: 'Hapus template',
  );
  if (confirmed) {
    await controller.deleteTemplate(template);
  }
}

String _transactionAtFromDate(DateTime date) {
  // Anchor to local noon so the date stays stable across the UTC conversion.
  final anchored = DateTime(date.year, date.month, date.day, 12);
  return anchored.toUtc().toIso8601String();
}

String _typeLabel(TransactionType type) {
  return switch (type) {
    TransactionType.expense => 'Pengeluaran',
    TransactionType.income => 'Pemasukan',
    TransactionType.transfer => 'Transfer',
    TransactionType.adjustment => 'Penyesuaian',
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

const _templateTypes = [
  TransactionType.expense,
  TransactionType.income,
  TransactionType.transfer,
  TransactionType.adjustment,
];
