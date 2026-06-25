import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/date_picker_field.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/goal_controller.dart';
import '../data/goal_models.dart';

/// Opens the contribution flow for [goal]. Funding a goal is a `transfer`
/// transaction from a source wallet into the goal's own goal-type wallet.
Future<void> showGoalContributeSheet(BuildContext context, Goal goal) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _GoalContributeSheet(goal: goal),
  );
}

class _GoalContributeSheet extends ConsumerStatefulWidget {
  const _GoalContributeSheet({required this.goal});

  final Goal goal;

  @override
  ConsumerState<_GoalContributeSheet> createState() =>
      _GoalContributeSheetState();
}

class _GoalContributeSheetState extends ConsumerState<_GoalContributeSheet> {
  int? _amountMinor;
  String? _sourceWalletId;
  DateTime _contributedAt = DateTime.now();
  String? _error;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final walletsAsync = ref.watch(walletListProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AffluenaSpacing.space5,
            AffluenaSpacing.space2,
            AffluenaSpacing.space5,
            MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Contribute', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space1),
              Text(
                widget.goal.name,
                style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              walletsAsync.when(
                loading: () => const _ContributeFormSkeleton(),
                error: (_, _) => AffluenaBanner.error(
                  'Wallets could not be loaded.',
                  onRetry: () => ref.invalidate(walletListProvider),
                ),
                data: (wallets) => _buildForm(context, wallets),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Wallet> wallets) {
    final goalWallet = _findGoalWallet(wallets);
    final sourceWallets = _sourceWallets(wallets, goalWallet);

    if (goalWallet == null) {
      return AffluenaBanner(
        message:
            'This goal has no linked goal wallet yet, so it cannot receive '
            'contributions.',
        tone: AffluenaBannerTone.warning,
      );
    }
    if (sourceWallets.isEmpty) {
      return const AffluenaBanner(
        message:
            'Add a spending wallet first — contributions transfer from one of '
            'your wallets into this goal.',
        tone: AffluenaBannerTone.info,
      );
    }

    final selected = _selectedSource(sourceWallets);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoneyInput(
          key: const Key('goal-contribute-amount-field'),
          label: 'Amount',
          initialValue: _amountMinor,
          enabled: !_isSaving,
          autofocus: true,
          onChanged: (value) => setState(() {
            _amountMinor = value;
            _error = null;
          }),
        ),
        const SizedBox(height: AffluenaSpacing.space2),
        SelectorRow(
          label: 'From wallet',
          value: selected == null
              ? 'Select a wallet'
              : '${selected.name} · ${MoneyFormatter.idr(selected.balanceMinor)}',
          icon: Icons.account_balance_wallet_outlined,
          enabled: !_isSaving,
          onTap: () => _pickSource(context, sourceWallets),
        ),
        const SizedBox(height: AffluenaSpacing.space2),
        DatePickerField(
          label: 'Contribution date',
          value: _contributedAt,
          enabled: !_isSaving,
          lastDate: DateTime.now(),
          onChanged: (value) => setState(() {
            _contributedAt = value;
            _error = null;
          }),
        ),
        if (_error != null) ...[
          const SizedBox(height: AffluenaSpacing.space4),
          AffluenaBanner.error(_error!, onRetry: () => _save(goalWallet)),
        ],
        const SizedBox(height: AffluenaSpacing.space5),
        FilledButton(
          key: const Key('goal-contribute-save-button'),
          onPressed: _isSaving ? null : () => _save(goalWallet),
          child: Text(_isSaving ? 'Contributing...' : 'Contribute'),
        ),
      ],
    );
  }

  Wallet? _selectedSource(List<Wallet> sources) {
    final id = _sourceWalletId;
    if (id == null) return null;
    for (final wallet in sources) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  Future<void> _pickSource(BuildContext context, List<Wallet> sources) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) =>
          _SourceWalletPicker(wallets: sources, selectedId: _sourceWalletId),
    );
    if (picked != null) {
      setState(() {
        _sourceWalletId = picked;
        _error = null;
      });
    }
  }

  Future<void> _save(Wallet goalWallet) async {
    final amount = _amountMinor ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    final source = _sourceWalletId;
    if (source == null) {
      setState(() => _error = 'Choose the wallet to contribute from.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final success = await ref
        .read(goalControllerProvider.notifier)
        .contribute(
          goal: widget.goal,
          sourceWalletId: source,
          goalWalletId: goalWallet.id,
          amountMinor: amount,
          contributedAt: _contributedAt,
        );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSaving = false;
      _error = 'Contribution could not be recorded. Try again.';
    });
  }

  Wallet? _findGoalWallet(List<Wallet> wallets) {
    for (final wallet in wallets) {
      if (wallet.isGoal && wallet.goalId == widget.goal.id) return wallet;
    }
    return null;
  }

  List<Wallet> _sourceWallets(List<Wallet> wallets, Wallet? goalWallet) {
    return wallets
        .where((wallet) => !wallet.isGoal && wallet.id != goalWallet?.id)
        .toList(growable: false);
  }
}

class _SourceWalletPicker extends StatelessWidget {
  const _SourceWalletPicker({required this.wallets, required this.selectedId});

  final List<Wallet> wallets;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

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
            Text('From wallet', style: textTheme.titleLarge),
            const SizedBox(height: AffluenaSpacing.space3),
            for (final wallet in wallets)
              Padding(
                padding: const EdgeInsets.only(bottom: AffluenaSpacing.space1),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(wallet.id),
                    borderRadius: BorderRadius.circular(AffluenaRadii.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AffluenaSpacing.space3,
                        horizontal: AffluenaSpacing.space2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(wallet.name, style: textTheme.bodyLarge),
                                const SizedBox(height: AffluenaSpacing.space1),
                                Text(
                                  MoneyFormatter.idr(wallet.balanceMinor),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (wallet.id == selectedId)
                            Icon(
                              Icons.check_circle,
                              color: colors.forest,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContributeFormSkeleton extends StatelessWidget {
  const _ContributeFormSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        AffluenaSkeleton(height: 56, radius: AffluenaRadii.control),
        SizedBox(height: AffluenaSpacing.space3),
        AffluenaSkeleton(height: 56, radius: AffluenaRadii.control),
        SizedBox(height: AffluenaSpacing.space3),
        AffluenaSkeleton(height: 56, radius: AffluenaRadii.control),
        SizedBox(height: AffluenaSpacing.space5),
        AffluenaSkeleton(height: 48, radius: AffluenaRadii.control),
      ],
    );
  }
}
