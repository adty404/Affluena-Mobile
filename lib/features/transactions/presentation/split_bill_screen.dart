import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../shared/presentation/widgets/date_time_picker_field.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../tags/data/tag_models.dart';
import '../application/split_bill_controller.dart';
import '../data/transaction_models.dart';
import 'split_bill_participant_sheet.dart';
import 'transactions_screen.dart';

part 'split_bill_screen_form_widgets.dart';
part 'split_bill_screen_info_widgets.dart';
part 'split_bill_screen_result_widgets.dart';

class SplitBillScreen extends ConsumerStatefulWidget {
  const SplitBillScreen({super.key});

  static const path = '/transactions/split/new';

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen> {
  late final TextEditingController _noteController;
  final _participants = <SplitBillParticipantDraft>[];

  int? _totalAmountMinor;
  DateTime _date = DateTime.now();
  String? _walletId;
  String? _categoryId;
  String? _tagId;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    // Clear any "created" result/error from a previous visit so a stale success
    // card never lingers when the form is reopened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(splitBillControllerProvider.notifier).clearResult();
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splitBillControllerProvider);
    final controller = ref.read(splitBillControllerProvider.notifier);

    if (state.isLoading && state.wallets.isEmpty) {
      return const _SplitBillLoading();
    }

    if (state.loadError != null && state.wallets.isEmpty) {
      return _SplitBillLoadError(onRetry: controller.load);
    }

    final walletId = _walletId ?? state.wallets.firstOrNull?.id;
    final categoryId = _categoryId ?? state.expenseCategories.firstOrNull?.id;
    final totalAmount = _totalAmountMinor ?? 0;
    final participantTotal = _participantTotal;
    final userShare = totalAmount - participantTotal;
    final splitError = _splitValidationError(totalAmount, participantTotal);
    final canSubmit =
        !state.isSaving &&
        walletId != null &&
        categoryId != null &&
        totalAmount > 0 &&
        _participants.isNotEmpty &&
        splitError == null;

    return DrillInScaffold(
      title: 'Bagi tagihan',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          const _SplitBillIntro(),
          const SizedBox(height: AffluenaSpacing.space5),
          _SplitSummary(
            totalAmount: totalAmount,
            participantTotal: participantTotal,
            userShare: userShare,
            participantCount: _participants.length,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          _SplitBillInfoSection(
            state: state,
            onCategoriesMutated: () =>
                ref.read(splitBillControllerProvider.notifier).load(),
            walletId: walletId,
            categoryId: categoryId,
            selectedTagId: _tagId,
            totalAmountMinor: _totalAmountMinor,
            date: _date,
            noteController: _noteController,
            onAmountChanged: (value) => setState(() {
              _totalAmountMinor = value;
              _formError = null;
            }),
            onDateChanged: (value) => setState(() {
              _date = value;
              _formError = null;
            }),
            onWalletChanged: (value) => setState(() {
              _walletId = value;
              _formError = null;
            }),
            onCategoryChanged: (value) => setState(() {
              _categoryId = value;
              _formError = null;
            }),
            onTagChanged: (value) => setState(() {
              _tagId = value;
              _formError = null;
            }),
            onTextChanged: () => setState(() => _formError = null),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SectionHeader(
            title: 'Peserta',
            actionLabel: '${_participants.length} ditambahkan',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          _ParticipantList(
            participants: _participants,
            totalAmountMinor: totalAmount,
            onAdd: state.isSaving ? null : () => _addParticipant(state),
            onRemove: state.isSaving
                ? null
                : (index) => setState(() {
                    _participants.removeAt(index);
                    _formError = null;
                  }),
          ),
          if (splitError != null || _formError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner(
              message: splitError ?? _formError!,
              tone: AffluenaBannerTone.warning,
            ),
          ],
          if (state.actionError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner.error(state.actionError!),
          ],
          if (state.result != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            _SplitResultCard(result: state.result!),
          ],
          const SizedBox(height: AffluenaSpacing.space5),
          FilledButton.icon(
            key: const Key('split-submit-button'),
            onPressed: canSubmit
                ? () => _confirmSubmit(state, walletId, categoryId)
                : null,
            icon: const Icon(Icons.call_split_outlined),
            label: Text(state.isSaving ? 'Membuat...' : 'Buat bagi tagihan'),
          ),
        ],
      ),
    );
  }

  int get _participantTotal {
    return _participants.fold<int>(
      0,
      (total, participant) => total + participant.amountMinor,
    );
  }

  String? _splitValidationError(int totalAmount, int participantTotal) {
    if (totalAmount <= 0 || participantTotal == 0) return null;
    if (participantTotal > totalAmount) {
      return 'Bagian peserta melebihi total tagihan.';
    }
    return null;
  }

  Future<void> _addParticipant(SplitBillState state) async {
    final participant = await showSplitBillParticipantSheet(
      context: context,
      state: state,
    );
    if (!mounted || participant == null) return;
    setState(() {
      _participants.add(participant);
      _formError = null;
    });
  }

  Future<void> _confirmSubmit(
    SplitBillState state,
    String walletId,
    String categoryId,
  ) async {
    // Validate completeness BEFORE opening the confirmation sheet so users
    // never confirm a form that will immediately fail afterwards.
    final totalAmount = _totalAmountMinor ?? 0;
    final splitError = _splitValidationError(totalAmount, _participantTotal);
    if (splitError != null ||
        totalAmount <= 0 ||
        _participants.isEmpty ||
        walletId.isEmpty ||
        categoryId.isEmpty) {
      setState(() {
        _formError =
            splitError ??
            'Lengkapi detail bagi tagihan yang valid sebelum mengirim.';
      });
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _SplitConfirmSheet(
        totalAmount: totalAmount,
        participantTotal: _participantTotal,
        participantCount: _participants.length,
      ),
    );
    if (!mounted || confirmed != true) return;
    await _submit(state, walletId, categoryId);
  }

  Future<void> _submit(
    SplitBillState state,
    String walletId,
    String categoryId,
  ) async {
    final totalAmount = _totalAmountMinor ?? 0;
    final request = SplitTransactionRequest(
      walletId: walletId,
      categoryId: categoryId,
      totalAmountMinor: totalAmount,
      transactionAt: _transactionAtFromDate(_date),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      tagIds: _tagId == null ? const [] : [_tagId!],
      splits: _participants
          .map((participant) => participant.toSplit())
          .toList(growable: false),
    );

    setState(() => _formError = null);
    await ref
        .read(splitBillControllerProvider.notifier)
        .createSplitBill(request);
    // The success result card (with View transactions/debts) renders from state.
    // It is cleared on the next visit via clearResult() in initState, so it no
    // longer lingers when the form is reopened from the split-bill list.
  }
}

String _transactionAtFromDate(DateTime date) {
  // Send the full local date+time (UTC-normalized) so split bills can be
  // backdated and carry a time-of-day, matching the other transaction inputs.
  return date.toUtc().toIso8601String();
}
