import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/tags/data/tag_models.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/transactions/presentation/split_bill_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'transactions_test_helpers.dart';

void main() {
  setUpAll(() async {
    // The split date is now a DatePickerField that formats the chosen date with
    // the 'id_ID' locale (mirroring main()); without this the form throws on
    // locale data when it builds.
    await initializeDateFormatting('id_ID');
  });

  testWidgets(
    'creates split bill with participant allocation and display-name selectors',
    (tester) async {
      final repository = SplitBillRecordingRepository(
        response: const SplitTransactionResponse(
          transactionId: 'transaction-split',
          debtIds: ['debt-rani', 'debt-bima'],
        ),
      );

      await tester.pumpWidget(
        splitBillTestApp(transactionRepository: repository),
      );
      await tester.pumpSplitState();

      expect(find.text('Split bill'), findsOneWidget);
      expect(find.text('GoPay'), findsWidgets);
      expect(find.text('Food & Dining'), findsWidgets);
      expect(find.text(gopayWallet.id), findsNothing);
      expect(find.text(foodCategory.id), findsNothing);

      await tester.enterText(
        find.byKey(const Key('split-total-amount-field')),
        '300000',
      );
      // The date is now a tappable DatePickerField backed by the native picker.
      // Open it and pick the 22nd of the current month (June 2026).
      final dateField = find.byKey(const Key('split-date-field'));
      await tester.scrollUntilVisible(
        dateField,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(dateField);
      await tester.pumpAndSettle();
      await tester.tap(dateField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('22'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('split-note-field')),
        'Dinner at Sate Senayan',
      );
      final tagChip = find.byKey(Key('split-tag-chip-${monthlyTag.id}'));
      await Scrollable.ensureVisible(
        tester.element(tagChip),
        alignment: 0.45,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(tagChip);
      await tester.pumpAndSettle();

      await _addParticipant(tester, name: 'Rani', amount: '120000');
      await _addParticipant(tester, name: 'Bima', amount: '80000');

      await tester.scrollUntilVisible(
        find.text('Bima'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Rani'), findsOneWidget);
      expect(find.text('Bima'), findsOneWidget);

      await _tapSubmit(tester);
      await tester.pumpAndSettle();
      final confirmSheet = find.byKey(const Key('split-confirm-sheet'));
      expect(confirmSheet, findsOneWidget);
      expect(
        find.descendant(
          of: confirmSheet,
          matching: find.text('Create split bill'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: confirmSheet, matching: find.text('Your share')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: confirmSheet, matching: find.text('Rp 100.000')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: confirmSheet,
          matching: find.text('Participant share'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: confirmSheet, matching: find.text('Rp 200.000')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('split-confirm-button')));
      await tester.pumpSplitState();

      expect(repository.splitRequests, hasLength(1));
      final request = repository.splitRequests.single;
      expect(request.walletId, gopayWallet.id);
      expect(request.categoryId, foodCategory.id);
      expect(request.totalAmountMinor, 300000);
      expect(request.tagIds, [monthlyTag.id]);
      expect(request.note, 'Dinner at Sate Senayan');
      expect(request.transactionAt, contains('2026-06-22'));
      expect(request.splits, hasLength(2));
      expect(request.splits.first.counterpartyName, 'Rani');
      expect(request.splits.first.amountMinor, 120000);
      expect(request.splits.first.disbursementCategoryId, foodCategory.id);
      expect(request.splits.first.paymentCategoryId, salaryCategory.id);

      expect(find.text('Split bill created'), findsOneWidget);
      expect(find.text('Expense transaction recorded'), findsOneWidget);
      expect(find.text('2 debt records created'), findsOneWidget);
      expect(find.text('View transactions'), findsOneWidget);
      expect(find.text('View debts'), findsOneWidget);
    },
  );

  testWidgets('blocks over-split participant totals before submit', (
    tester,
  ) async {
    final repository = SplitBillRecordingRepository(
      response: const SplitTransactionResponse(
        transactionId: 'transaction-split',
        debtIds: ['debt-rani'],
      ),
    );

    await tester.pumpWidget(
      splitBillTestApp(transactionRepository: repository),
    );
    await tester.pumpSplitState();

    await tester.enterText(
      find.byKey(const Key('split-total-amount-field')),
      '100000',
    );
    await _addParticipant(tester, name: 'Rani', amount: '120000');

    await tester.scrollUntilVisible(
      find.text('Participant share exceeds total bill.'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Participant share exceeds total bill.'), findsOneWidget);

    await _tapSubmit(tester, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repository.splitRequests, isEmpty);
    expect(find.byKey(const Key('split-confirm-sheet')), findsNothing);
  });

  testWidgets('API failure keeps split form visible with error feedback', (
    tester,
  ) async {
    final repository = SplitBillRecordingRepository(
      response: const SplitTransactionResponse(
        transactionId: 'transaction-split',
        debtIds: ['debt-rani'],
      ),
      splitError: Exception('rollback'),
    );

    await tester.pumpWidget(
      splitBillTestApp(transactionRepository: repository),
    );
    await tester.pumpSplitState();

    await tester.enterText(
      find.byKey(const Key('split-total-amount-field')),
      '160000',
    );
    await _addParticipant(tester, name: 'Rani', amount: '80000');

    await _tapSubmit(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('split-confirm-button')));
    await tester.pumpSplitState();

    expect(repository.splitRequests, hasLength(1));
    expect(find.text('Split bill could not be created.'), findsOneWidget);
    expect(find.text('Rani'), findsOneWidget);
    expect(find.text('Split bill created'), findsNothing);
  });
}

Widget splitBillTestApp({
  required SplitBillRecordingRepository transactionRepository,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      transactionRepositoryProvider.overrideWithValue(transactionRepository),
      walletRepositoryProvider.overrideWithValue(
        const StaticWalletRepository(wallets: [gopayWallet, bcaWallet]),
      ),
      categoryRepositoryProvider.overrideWithValue(
        const StaticCategoryRepository(
          categories: [foodCategory, salaryCategory],
        ),
      ),
      tagRepositoryProvider.overrideWithValue(
        const StaticSplitTagRepository(tags: [monthlyTag]),
      ),
    ],
    child: MaterialApp(
      theme: AffluenaTheme.light,
      darkTheme: AffluenaTheme.dark,
      home: const Scaffold(body: SplitBillScreen()),
    ),
  );
}

Future<void> _addParticipant(
  WidgetTester tester, {
  required String name,
  required String amount,
}) async {
  final addButton = find.byKey(const Key('split-add-participant-button'));
  await tester.scrollUntilVisible(
    addButton,
    280,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(
    tester.element(addButton),
    alignment: 0.35,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(addButton, warnIfMissed: false);
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('participant-name-field')), name);
  await tester.enterText(
    find.byKey(const Key('participant-amount-field')),
    amount,
  );
  final saveButton = find.byKey(const Key('participant-save-button'));
  await Scrollable.ensureVisible(
    tester.element(saveButton),
    alignment: 0.8,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(saveButton, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _tapSubmit(WidgetTester tester, {bool warnIfMissed = true}) async {
  final submitButton = find.byKey(const Key('split-submit-button'));
  await tester.scrollUntilVisible(
    submitButton,
    280,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(
    tester.element(submitButton),
    alignment: 0.7,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(submitButton, warnIfMissed: warnIfMissed);
}

extension on WidgetTester {
  Future<void> pumpSplitState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

class SplitBillRecordingRepository implements TransactionRepository {
  SplitBillRecordingRepository({required this.response, this.splitError});

  final SplitTransactionResponse response;
  final Object? splitError;
  final splitRequests = <SplitTransactionRequest>[];

  @override
  Future<TransactionListResponse> listTransactions({
    TransactionType? type,
    String? walletId,
    String? categoryId,
    String? tagId,
    String? from,
    String? to,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return TransactionListResponse(
      transactions: const [],
      pagination: Pagination(total: 0, limit: limit ?? 0, offset: offset ?? 0),
    );
  }

  @override
  Future<Transaction> getTransaction(String id) async => groceriesTransaction;

  @override
  Future<Transaction> createTransaction(TransactionRequest request) async {
    return groceriesTransaction;
  }

  @override
  Future<SplitTransactionResponse> splitBill(
    SplitTransactionRequest request,
  ) async {
    splitRequests.add(request);
    if (splitError != null) throw splitError!;
    return response;
  }

  @override
  Future<void> deleteTransaction(String id) async {}
}

class StaticSplitTagRepository implements TagRepository {
  const StaticSplitTagRepository({required this.tags});

  final List<Tag> tags;

  @override
  Future<TagListResponse> listTags({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return TagListResponse(
      tags: tags,
      pagination: Pagination(
        total: tags.length,
        limit: limit ?? tags.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Tag> createTag(TagRequest request) async => tags.first;

  @override
  Future<Tag> getTag(String id) async {
    return tags.firstWhere((tag) => tag.id == id);
  }

  @override
  Future<Tag> updateTag(String id, TagRequest request) async => getTag(id);

  @override
  Future<void> deleteTag(String id) async {}
}

const monthlyTag = Tag(
  id: 'tag-monthly',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'MonthlyBill',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
