import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/tag_formatter.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/date_picker_field.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../application/transactions_controller.dart';

/// Opens the filter sheet seeded with the current filters. Returns the new
/// [TransactionFilters] to apply, or null if the user dismissed without
/// applying. The sheet stays open on validation issues and only pops on apply.
Future<TransactionFilters?> showTransactionFilterSheet({
  required BuildContext context,
  required TransactionsState state,
}) {
  return showModalBottomSheet<TransactionFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _TransactionFilterSheet(state: state),
  );
}

class _TransactionFilterSheet extends StatefulWidget {
  const _TransactionFilterSheet({required this.state});

  final TransactionsState state;

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  late String? _walletId;
  late String? _categoryId;
  late String? _tagId;
  late DateTime? _from;
  late DateTime? _to;
  String? _error;

  @override
  void initState() {
    super.initState();
    final filters = widget.state.filters;
    _walletId = filters.walletId;
    _categoryId = filters.categoryId;
    _tagId = filters.tagId;
    _from = filters.from;
    _to = filters.to;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final state = widget.state;

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
              Text('Saring transaksi', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              SelectorRow(
                key: const Key('filter-wallet-selector'),
                label: 'Dompet',
                value: _walletId == null
                    ? 'Semua dompet'
                    : state.walletName(_walletId!),
                icon: Icons.account_balance_wallet_outlined,
                enabled: state.wallets.isNotEmpty,
                onTap: state.wallets.isEmpty ? null : _selectWallet,
              ),
              const Divider(height: 1),
              SelectorRow(
                key: const Key('filter-category-selector'),
                label: 'Kategori',
                value: _categoryId == null
                    ? 'Semua kategori'
                    : (state.categoryNames[_categoryId] ?? 'Kategori'),
                icon: Icons.category_outlined,
                enabled: state.categories.isNotEmpty,
                onTap: state.categories.isEmpty ? null : _selectCategory,
              ),
              const Divider(height: 1),
              SelectorRow(
                key: const Key('filter-tag-selector'),
                label: 'Tag',
                value: _tagId == null
                    ? 'Semua tag'
                    : tagLabel(state.tagName(_tagId!)),
                icon: Icons.sell_outlined,
                enabled: state.tags.isNotEmpty,
                onTap: state.tags.isEmpty ? null : _selectTag,
              ),
              const Divider(height: 1),
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                key: const Key('filter-from-date-field'),
                label: 'Dari tanggal',
                value: _from,
                lastDate: _to ?? DateTime.now(),
                placeholder: 'Tanggal mulai apa saja',
                onChanged: (value) => setState(() {
                  _from = value;
                  _error = null;
                }),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                key: const Key('filter-to-date-field'),
                label: 'Sampai tanggal',
                value: _to,
                firstDate: _from,
                placeholder: 'Tanggal akhir apa saja',
                onChanged: (value) => setState(() {
                  _to = value;
                  _error = null;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                Text(
                  _error!,
                  style: textTheme.bodySmall?.copyWith(color: colors.coral),
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('filter-reset-button'),
                      onPressed: _hasAnySelection ? _reset : null,
                      child: const Text('Atur ulang'),
                    ),
                  ),
                  const SizedBox(width: AffluenaSpacing.space3),
                  Expanded(
                    child: FilledButton(
                      key: const Key('filter-apply-button'),
                      onPressed: _apply,
                      child: const Text('Terapkan filter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasAnySelection =>
      _walletId != null ||
      _categoryId != null ||
      _tagId != null ||
      _from != null ||
      _to != null;

  Future<void> _selectWallet() async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Saring berdasarkan dompet',
      selectedValue: _walletId,
      options: [
        for (final wallet in widget.state.wallets)
          LookupSelectorOption<String>(
            value: wallet.id,
            label: wallet.name,
            subtitle: wallet.type.name,
            icon: Icons.account_balance_wallet_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      _walletId = _walletId == selected ? null : selected;
      _error = null;
    });
  }

  Future<void> _selectCategory() async {
    // Categories are a hierarchy: use the tree-aware picker, not a flat list.
    // Picking a parent filters its whole subtree (the API matches descendants).
    final selected = await showCategoryTreePicker(
      context: context,
      title: 'Saring berdasarkan kategori',
      selectedId: _categoryId,
      allowNone: true,
      noneLabel: 'Semua kategori',
      categories: [
        for (final category in widget.state.categories)
          CategoryTreeEntry(
            id: category.id,
            name: category.name,
            parentId: category.parentId,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      _categoryId = selected.isEmpty ? null : selected;
      _error = null;
    });
  }

  Future<void> _selectTag() async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Saring berdasarkan tag',
      selectedValue: _tagId,
      options: [
        for (final tag in widget.state.tags)
          LookupSelectorOption<String>(
            value: tag.id,
            label: tagLabel(tag.name),
            icon: Icons.sell_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      _tagId = _tagId == selected ? null : selected;
      _error = null;
    });
  }

  void _reset() {
    setState(() {
      _walletId = null;
      _categoryId = null;
      _tagId = null;
      _from = null;
      _to = null;
      _error = null;
    });
  }

  void _apply() {
    if (_from != null && _to != null && _to!.isBefore(_from!)) {
      setState(
        () => _error = 'Tanggal akhir harus sama atau setelah tanggal mulai.',
      );
      return;
    }
    Navigator.of(context).pop(
      TransactionFilters(
        type: widget.state.filters.type,
        walletId: _walletId,
        categoryId: _categoryId,
        tagId: _tagId,
        from: _from,
        to: _to,
      ),
    );
  }
}
