import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/application/financial_refresh.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/date_time_picker_field.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../data/wallet_models.dart';

/// Lets the user set a wallet to a new balance. The difference is recorded as an
/// `adjustment` (penyesuaian) transaction — a positive delta raises the balance,
/// a negative delta lowers it — so the change stays in the audit trail.
Future<bool?> showWalletAdjustSheet(BuildContext context, Wallet wallet) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _WalletAdjustSheet(wallet: wallet),
  );
}

class _WalletAdjustSheet extends ConsumerStatefulWidget {
  const _WalletAdjustSheet({required this.wallet});

  final Wallet wallet;

  @override
  ConsumerState<_WalletAdjustSheet> createState() => _WalletAdjustSheetState();
}

class _WalletAdjustSheetState extends ConsumerState<_WalletAdjustSheet> {
  late int _targetMinor = widget.wallet.balanceMinor;
  final _noteController = TextEditingController();
  DateTime _dateTime = DateTime.now();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _delta => _targetMinor - widget.wallet.balanceMinor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final delta = _delta;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AffluenaSpacing.space5,
          right: AffluenaSpacing.space5,
          bottom:
              MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sesuaikan saldo', style: textTheme.titleLarge),
            const SizedBox(height: AffluenaSpacing.space1),
            Text(
              'Saldo saat ini ${MoneyFormatter.idr(widget.wallet.balanceMinor)}',
              style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            MoneyInput(
              key: const Key('wallet-adjust-amount-field'),
              label: 'Saldo baru',
              // Bare digits: MoneyInput hardcodes the 'Rp ' prefix.
              hint: '1.250.000',
              helperText:
                  'Masukkan saldo target — selisihnya dicatat sebagai '
                  'penyesuaian.',
              initialValue: widget.wallet.balanceMinor,
              enabled: !_isSaving,
              onChanged: (value) => setState(() {
                _targetMinor = value ?? 0;
                _error = null;
              }),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            if (delta != 0)
              Text(
                delta > 0
                    ? 'Naik ${MoneyFormatter.idr(delta)} (dicatat sebagai penyesuaian)'
                    : 'Turun ${MoneyFormatter.idr(-delta)} (dicatat sebagai penyesuaian)',
                style: textTheme.bodySmall?.copyWith(
                  color: delta > 0 ? colors.success : colors.coral,
                ),
              ),
            const SizedBox(height: AffluenaSpacing.space3),
            DateTimePickerField(
              key: const Key('wallet-adjust-datetime-field'),
              label: 'Tanggal & waktu',
              value: _dateTime,
              enabled: !_isSaving,
              onChanged: (value) => setState(() {
                _dateTime = value;
                _error = null;
              }),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            TextField(
              controller: _noteController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notes_outlined),
                labelText: 'Catatan',
                hintText: 'cth: Selisih saldo ATM',
                helperText: 'Opsional',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AffluenaSpacing.space3),
              AffluenaBanner.error(_error!),
            ],
            const SizedBox(height: AffluenaSpacing.space5),
            FilledButton(
              key: const Key('wallet-adjust-save-button'),
              onPressed: _isSaving || delta == 0 ? null : _save,
              child: Text(_isSaving ? 'Menyimpan...' : 'Simpan penyesuaian'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final delta = _delta;
    if (delta == 0) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final note = _noteController.text.trim();
    final request = TransactionRequest(
      type: TransactionType.adjustment,
      walletId: widget.wallet.id,
      // Adjustment uses a signed amount: positive raises, negative lowers.
      amountMinor: delta,
      transactionAt: _dateTime.toUtc().toIso8601String(),
      note: note.isEmpty ? 'Penyesuaian saldo' : note,
    );

    try {
      await ref.read(transactionRepositoryProvider).createTransaction(request);
      ref.invalidateFinancialData();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Saldo tidak dapat disesuaikan.';
      });
    }
  }
}
