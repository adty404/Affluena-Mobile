import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../debts/presentation/debt_screen.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
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

  static const path = '/transactions/split';

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen> {
  late final TextEditingController _totalAmountController;
  late final TextEditingController _dateController;
  late final TextEditingController _noteController;
  final _participants = <SplitBillParticipantDraft>[];

  String? _walletId;
  String? _categoryId;
  String? _tagId;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _totalAmountController = TextEditingController();
    _dateController = TextEditingController(text: _todayDate());
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _totalAmountController.dispose();
    _dateController.dispose();
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
    final totalAmount = _parseAmount(_totalAmountController.text);
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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          _SplitBillHeader(onBack: () => context.go(TransactionsScreen.path)),
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
            walletId: walletId,
            categoryId: categoryId,
            selectedTagId: _tagId,
            totalAmountController: _totalAmountController,
            dateController: _dateController,
            noteController: _noteController,
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
            title: 'Participants',
            actionLabel: '${_participants.length} added',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          _ParticipantList(
            participants: _participants,
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
            _FeedbackCard(message: splitError ?? _formError!, isError: true),
          ],
          if (state.actionError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            _FeedbackCard(message: state.actionError!, isError: true),
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
            label: Text(state.isSaving ? 'Creating...' : 'Create split bill'),
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
      return 'Participant share exceeds total bill.';
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
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _SplitConfirmSheet(
        totalAmount: _parseAmount(_totalAmountController.text),
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
    final totalAmount = _parseAmount(_totalAmountController.text);
    final splitError = _splitValidationError(totalAmount, _participantTotal);
    if (splitError != null ||
        totalAmount <= 0 ||
        _participants.isEmpty ||
        walletId.isEmpty ||
        categoryId.isEmpty) {
      setState(() {
        _formError =
            splitError ?? 'Complete valid split details before submitting.';
      });
      return;
    }

    final request = SplitTransactionRequest(
      walletId: walletId,
      categoryId: categoryId,
      totalAmountMinor: totalAmount,
      transactionAt: _transactionAtFromDate(_dateController.text),
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
  }
}

int _parseAmount(String raw) {
  return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

String _transactionAtFromDate(String raw) {
  final value = raw.trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return '${value}T00:00:00Z';
  }
  return value.isEmpty ? '${_todayDate()}T00:00:00Z' : value;
}

String _todayDate() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

String _tagLabel(String name) {
  final normalized = name.trim().replaceFirst(RegExp(r'^#+'), '');
  return normalized.isEmpty ? '#' : '#$normalized';
}
