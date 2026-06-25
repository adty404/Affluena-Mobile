import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/tag_formatter.dart';
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
              Text('Filter transactions', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              SelectorRow(
                key: const Key('filter-wallet-selector'),
                label: 'Wallet',
                value: _walletId == null
                    ? 'Any wallet'
                    : state.walletName(_walletId!),
                icon: Icons.account_balance_wallet_outlined,
                enabled: state.wallets.isNotEmpty,
                onTap: state.wallets.isEmpty ? null : _selectWallet,
              ),
              const Divider(height: 1),
              SelectorRow(
                key: const Key('filter-category-selector'),
                label: 'Category',
                value: _categoryId == null
                    ? 'Any category'
                    : (state.categoryNames[_categoryId] ?? 'Category'),
                icon: Icons.category_outlined,
                enabled: state.categories.isNotEmpty,
                onTap: state.categories.isEmpty ? null : _selectCategory,
              ),
              const Divider(height: 1),
              SelectorRow(
                key: const Key('filter-tag-selector'),
                label: 'Tag',
                value: _tagId == null
                    ? 'Any tag'
                    : tagLabel(state.tagName(_tagId!)),
                icon: Icons.sell_outlined,
                enabled: state.tags.isNotEmpty,
                onTap: state.tags.isEmpty ? null : _selectTag,
              ),
              const Divider(height: 1),
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                key: const Key('filter-from-date-field'),
                label: 'From date',
                value: _from,
                lastDate: _to ?? DateTime.now(),
                placeholder: 'Any start date',
                onChanged: (value) => setState(() {
                  _from = value;
                  _error = null;
                }),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                key: const Key('filter-to-date-field'),
                label: 'To date',
                value: _to,
                firstDate: _from,
                placeholder: 'Any end date',
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
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: AffluenaSpacing.space3),
                  Expanded(
                    child: FilledButton(
                      key: const Key('filter-apply-button'),
                      onPressed: _apply,
                      child: const Text('Apply filters'),
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
      title: 'Filter by wallet',
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
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Filter by category',
      selectedValue: _categoryId,
      options: [
        for (final category in widget.state.categories)
          LookupSelectorOption<String>(
            value: category.id,
            label: category.name,
            subtitle: category.type.name,
            icon: Icons.category_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      _categoryId = _categoryId == selected ? null : selected;
      _error = null;
    });
  }

  Future<void> _selectTag() async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Filter by tag',
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
      setState(() => _error = 'End date must be on or after the start date.');
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
