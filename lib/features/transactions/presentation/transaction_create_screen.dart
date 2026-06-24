import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/date_picker_field.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../tags/data/tag_models.dart';
import '../application/transaction_create_controller.dart';
import '../data/transaction_models.dart';
import 'adjustment_direction_control.dart';
import 'transactions_screen.dart';

class TransactionCreateScreen extends ConsumerStatefulWidget {
  const TransactionCreateScreen({super.key});

  static const path = '/transactions/new';

  @override
  ConsumerState<TransactionCreateScreen> createState() =>
      _TransactionCreateScreenState();
}

class _TransactionCreateScreenState
    extends ConsumerState<TransactionCreateScreen> {
  TransactionType _type = TransactionType.expense;
  int? _amountMinor;
  bool _decrease = false;
  String? _walletId;
  String? _toWalletId;
  String? _categoryId;
  String? _tagId;
  DateTime _date = DateTime.now();
  final _noteController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isTransfer => _type == TransactionType.transfer;

  bool get _isAdjustment => _type == TransactionType.adjustment;

  bool get _needsCategory =>
      _type == TransactionType.income || _type == TransactionType.expense;

  CategoryType get _categoryType => _type == TransactionType.income
      ? CategoryType.income
      : CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionCreateControllerProvider);
    final controller = ref.read(transactionCreateControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.wallets.isEmpty) {
      return const _TransactionCreateLoading();
    }

    if (state.loadError != null && state.wallets.isEmpty) {
      return _TransactionCreateLoadError(onRetry: controller.load);
    }

    final categories = _needsCategory
        ? state.categoriesOfType(_categoryType)
        : const <Category>[];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          _Header(onBack: () => context.go(TransactionsScreen.path)),
          const SizedBox(height: AffluenaSpacing.space5),
          SectionHeader(title: 'Type'),
          const SizedBox(height: AffluenaSpacing.space3),
          _TypeChips(
            selected: _type,
            enabled: !state.isSaving,
            onChanged: _onTypeChanged,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isAdjustment) ...[
                  AdjustmentDirectionControl(
                    decrease: _decrease,
                    enabled: !state.isSaving,
                    onChanged: (decrease) => setState(() {
                      _decrease = decrease;
                      _clearErrors();
                    }),
                  ),
                  const SizedBox(height: AffluenaSpacing.space3),
                ],
                MoneyInput(
                  key: const Key('transaction-create-amount-field'),
                  label: 'Amount',
                  initialValue: _amountMinor,
                  enabled: !state.isSaving,
                  onChanged: (value) => setState(() {
                    _amountMinor = value;
                    _validationError = null;
                  }),
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                SelectorRow(
                  key: const Key('transaction-create-wallet-selector'),
                  label: _isTransfer ? 'From wallet' : 'Wallet',
                  value: state.walletName(_walletId),
                  icon: Icons.account_balance_wallet_outlined,
                  enabled: state.wallets.isNotEmpty && !state.isSaving,
                  onTap: state.wallets.isEmpty ? null : _selectWallet,
                ),
                if (_isTransfer) ...[
                  const Divider(height: 1),
                  SelectorRow(
                    key: const Key('transaction-create-to-wallet-selector'),
                    label: 'To wallet',
                    value: state.walletName(_toWalletId),
                    icon: Icons.swap_horiz_rounded,
                    enabled: state.wallets.length > 1 && !state.isSaving,
                    onTap: state.wallets.length > 1 ? _selectToWallet : null,
                  ),
                ],
                if (_needsCategory) ...[
                  const Divider(height: 1),
                  SelectorRow(
                    key: const Key('transaction-create-category-selector'),
                    label: 'Category',
                    value: state.categoryName(_categoryId),
                    icon: Icons.category_outlined,
                    enabled: categories.isNotEmpty && !state.isSaving,
                    onTap: categories.isEmpty
                        ? null
                        : () => _selectCategory(categories),
                  ),
                ],
                const Divider(height: 1),
                const SizedBox(height: AffluenaSpacing.space3),
                DatePickerField(
                  key: const Key('transaction-create-date-field'),
                  label: 'Date',
                  value: _date,
                  enabled: !state.isSaving,
                  lastDate: DateTime.now(),
                  onChanged: (value) => setState(() {
                    _date = value;
                    _validationError = null;
                  }),
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                TextField(
                  key: const Key('transaction-create-note-field'),
                  controller: _noteController,
                  enabled: !state.isSaving,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.notes_outlined),
                    labelText: 'Note (optional)',
                  ),
                  onChanged: (_) => _clearErrors(),
                ),
              ],
            ),
          ),
          if (state.tags.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space5),
            SectionHeader(title: 'Tag'),
            const SizedBox(height: AffluenaSpacing.space3),
            _TagChips(
              tags: state.tags,
              selectedTagId: _tagId,
              enabled: !state.isSaving,
              onChanged: (value) => setState(() {
                _tagId = value;
                _clearErrors();
              }),
            ),
          ],
          if (_validationError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner(
              message: _validationError!,
              tone: AffluenaBannerTone.warning,
            ),
          ],
          if (state.actionError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner.error(
              state.actionError!,
              onRetry: () => _submit(state),
            ),
          ],
          const SizedBox(height: AffluenaSpacing.space5),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('transaction-create-submit-button'),
              onPressed: state.isSaving ? null : () => _submit(state),
              icon: const Icon(Icons.check),
              label: Text(
                state.isSaving ? 'Saving...' : 'Create transaction',
                style: textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTypeChanged(TransactionType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _categoryId = null;
      if (!_isTransfer) _toWalletId = null;
      if (!_isAdjustment) _decrease = false;
      _clearErrors();
    });
  }

  void _clearErrors() {
    if (_validationError == null && ref.read(transactionCreateControllerProvider).actionError == null) {
      return;
    }
    setState(() => _validationError = null);
    ref.read(transactionCreateControllerProvider.notifier).clearActionError();
  }

  Future<void> _selectWallet() async {
    final state = ref.read(transactionCreateControllerProvider);
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: _isTransfer ? 'From wallet' : 'Wallet',
      selectedValue: _walletId,
      options: [
        for (final wallet in state.wallets)
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
      _walletId = selected;
      if (_toWalletId == selected) _toWalletId = null;
      _clearErrors();
    });
  }

  Future<void> _selectToWallet() async {
    final state = ref.read(transactionCreateControllerProvider);
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'To wallet',
      selectedValue: _toWalletId,
      options: [
        for (final wallet in state.wallets)
          if (wallet.id != _walletId)
            LookupSelectorOption<String>(
              value: wallet.id,
              label: wallet.name,
              subtitle: wallet.type.name,
              icon: Icons.swap_horiz_rounded,
            ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      _toWalletId = selected;
      _clearErrors();
    });
  }

  Future<void> _selectCategory(List<Category> categories) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Category',
      selectedValue: _categoryId,
      options: [
        for (final category in categories)
          LookupSelectorOption<String>(
            value: category.id,
            label: category.name,
            icon: Icons.category_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      _categoryId = selected;
      _clearErrors();
    });
  }

  Future<void> _submit(TransactionCreateState state) async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    final note = _noteController.text.trim();
    final amount = _amountMinor!;
    final signed = _isAdjustment && _decrease ? -amount : amount;
    final request = TransactionRequest(
      type: _type,
      walletId: _walletId!,
      toWalletId: _isTransfer ? _toWalletId : null,
      categoryId: _needsCategory ? _categoryId : null,
      amountMinor: signed,
      transactionAt: _transactionAt(_date),
      note: note.isEmpty ? null : note,
      tagIds: _tagId == null ? const [] : [_tagId!],
    );

    final created = await ref
        .read(transactionCreateControllerProvider.notifier)
        .create(request);
    if (!mounted || !created) return;
    context.go(TransactionsScreen.path);
  }

  String? _validate() {
    if (_walletId == null) {
      return _isTransfer ? 'Source wallet is required.' : 'Wallet is required.';
    }
    if (!_isAdjustment && (_amountMinor == null || _amountMinor! <= 0)) {
      return 'Enter an amount greater than zero.';
    }
    if (_isAdjustment && (_amountMinor == null || _amountMinor! == 0)) {
      return 'Enter an amount greater than zero.';
    }
    if (_isTransfer) {
      if (_toWalletId == null) return 'Destination wallet is required.';
      if (_toWalletId == _walletId) {
        return 'Destination wallet must differ from the source wallet.';
      }
    }
    if (_needsCategory && _categoryId == null) {
      return 'Category is required.';
    }
    return null;
  }

  static String _transactionAt(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-${day}T00:00:00Z';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New transaction', style: textTheme.headlineMedium),
              const SizedBox(height: AffluenaSpacing.space1),
              Text(
                'Record income, an expense, a transfer, or a balance adjustment.',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          key: const Key('transaction-create-back-button'),
          tooltip: 'Back to transactions',
          onPressed: onBack,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final TransactionType selected;
  final bool enabled;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AffluenaSpacing.space2,
      runSpacing: AffluenaSpacing.space2,
      children: [
        for (final type in TransactionType.values)
          ChoiceChip(
            key: Key('transaction-create-type-${type.apiValue}'),
            label: Text(_typeLabel(type)),
            selected: selected == type,
            avatar: selected == type
                ? const Icon(Icons.check, size: 16)
                : null,
            onSelected: enabled ? (_) => onChanged(type) : null,
          ),
      ],
    );
  }
}

class _TagChips extends StatelessWidget {
  const _TagChips({
    required this.tags,
    required this.selectedTagId,
    required this.enabled,
    required this.onChanged,
  });

  final List<Tag> tags;
  final String? selectedTagId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AffluenaSpacing.space2,
      runSpacing: AffluenaSpacing.space2,
      children: [
        ChoiceChip(
          key: const Key('transaction-create-tag-none'),
          label: const Text('None'),
          selected: selectedTagId == null,
          onSelected: enabled ? (_) => onChanged(null) : null,
        ),
        for (final tag in tags)
          ChoiceChip(
            key: Key('transaction-create-tag-${tag.id}'),
            label: Text(_tagLabel(tag.name)),
            selected: selectedTagId == tag.id,
            onSelected: enabled ? (_) => onChanged(tag.id) : null,
          ),
      ],
    );
  }
}

class _TransactionCreateLoading extends StatelessWidget {
  const _TransactionCreateLoading();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          const AffluenaSkeleton.line(width: 200, height: 28),
          const SizedBox(height: AffluenaSpacing.space5),
          Wrap(
            spacing: AffluenaSpacing.space2,
            runSpacing: AffluenaSpacing.space2,
            children: const [
              AffluenaSkeleton(width: 84, height: 32, radius: AffluenaRadii.pill),
              AffluenaSkeleton(width: 92, height: 32, radius: AffluenaRadii.pill),
              AffluenaSkeleton(width: 96, height: 32, radius: AffluenaRadii.pill),
              AffluenaSkeleton(
                width: 110,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                AffluenaSkeleton(height: 48),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(height: 48),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(height: 48),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(height: 48),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaSkeleton(height: 48),
        ],
      ),
    );
  }
}

class _TransactionCreateLoadError extends StatelessWidget {
  const _TransactionCreateLoadError({required this.onRetry});

  final Future<void> Function() onRetry;

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
          Text('New transaction', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaBanner.error(
            'We could not load wallets and categories.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

String _typeLabel(TransactionType type) {
  return switch (type) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.transfer => 'Transfer',
    TransactionType.adjustment => 'Adjustment',
  };
}

String _tagLabel(String name) {
  final normalized = name.trim().replaceFirst(RegExp(r'^#+'), '');
  return normalized.isEmpty ? '#' : '#$normalized';
}
