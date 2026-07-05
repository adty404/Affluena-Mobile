import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/calc/due_window.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/state/copy_with_sentinel.dart';
import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../shared/application/financial_refresh.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/debt_models.dart';
import '../data/debt_repository.dart';
import 'debt_detail_controller.dart';

const debtPageSize = 20;

final debtControllerProvider = NotifierProvider<DebtController, DebtState>(
  DebtController.new,
);

class DebtController extends Notifier<DebtState> {
  @override
  DebtState build() {
    Future<void>.microtask(load);
    return const DebtState();
  }

  Future<void> load({bool reset = true}) async {
    if (state.isLoading || state.isLoadingMore) return;

    final offset = reset ? 0 : state.debts.length;
    state = state.copyWith(
      isLoading: reset,
      isLoadingMore: !reset,
      loadError: reset ? null : state.loadError,
      actionError: null,
    );

    try {
      final debtsFuture = ref
          .read(debtRepositoryProvider)
          .listDebts(
            limit: debtPageSize,
            offset: offset,
            sort: 'opened_at_desc',
          );
      final walletsFuture = ref
          .read(walletRepositoryProvider)
          .listWallets(limit: 100, offset: 0, sort: 'name_asc');
      final categoriesFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(limit: 100, offset: 0);

      final debtResponse = await debtsFuture;
      final walletResponse = await walletsFuture;
      final categoryResponse = await categoriesFuture;
      final selectableWallets = walletResponse.wallets
          .where((wallet) => !wallet.isGoal)
          .toList(growable: false);

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        loadError: null,
        debts: [if (!reset) ...state.debts, ...debtResponse.debts],
        total: debtResponse.pagination.total,
        wallets: selectableWallets,
        incomeCategories: categoryResponse.categories
            .where((category) => category.type == CategoryType.income)
            .toList(growable: false),
        expenseCategories: categoryResponse.categories
            .where((category) => category.type == CategoryType.expense)
            .toList(growable: false),
        walletNames: {
          for (final wallet in selectableWallets) wallet.id: wallet.name,
        },
        categoryNames: {
          for (final category in categoryResponse.categories)
            category.id: category.name,
        },
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        loadError: reset ? 'Utang gagal dimuat.' : state.loadError,
        actionError: reset ? null : 'Utang lainnya gagal dimuat.',
      );
    }
  }

  Future<void> loadMore() => load(reset: false);

  void dismissActionError() {
    if (state.actionError == null) return;
    state = state.copyWith(actionError: null);
  }

  void setTypeFilter(DebtType? type) {
    if (state.typeFilter == type) return;
    state = state.copyWith(typeFilter: type);
  }

  Future<void> createDebt(DebtRequest request) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await ref.read(debtRepositoryProvider).createDebt(request);
      ref.invalidateFinancialData();
      state = state.copyWith(isSaving: false);
      await load();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Utang gagal dibuat.',
      );
    }
  }

  Future<void> updateDebt(Debt debt, DebtUpdateRequest request) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await ref.read(debtRepositoryProvider).updateDebt(debt.id, request);
      ref.invalidateFinancialData();
      // The debt detail (remaining + payment timeline) is a non-autoDispose
      // family the balance set deliberately doesn't cover; refresh it directly.
      ref.invalidate(debtDetailProvider(debt.id));
      state = state.copyWith(isSaving: false);
      await load();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Utang gagal diperbarui.',
      );
    }
  }

  Future<void> payDebt(Debt debt, DebtPaymentRequest request) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await ref.read(debtRepositoryProvider).payDebt(debt.id, request);
      ref.invalidateFinancialData();
      // The debt detail (remaining + payment timeline) is a non-autoDispose
      // family the balance set deliberately doesn't cover; refresh it directly.
      ref.invalidate(debtDetailProvider(debt.id));
      state = state.copyWith(isSaving: false);
      await load();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Pembayaran utang gagal dicatat.',
      );
    }
  }

  Future<void> cancelDebt(Debt debt) async {
    await updateDebt(
      debt,
      DebtUpdateRequest(
        counterpartyName: debt.counterpartyName,
        // due_date is a date-only API field; never re-send the stored RFC3339
        // timestamp raw (the debt handler happens to tolerate it today, but
        // the date-only wire format is the contract).
        dueDate: debt.dueDate == null
            ? null
            : AffluenaDateFormatter.apiDate(debt.dueDate!),
        status: DebtStatus.cancelled,
        note: debt.note,
      ),
    );
  }
}

class DebtState {
  const DebtState({
    this.debts = const [],
    this.total = 0,
    this.wallets = const [],
    this.incomeCategories = const [],
    this.expenseCategories = const [],
    this.walletNames = const {},
    this.categoryNames = const {},
    this.typeFilter,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
  });

  final List<Debt> debts;
  final int total;
  final List<Wallet> wallets;
  final List<Category> incomeCategories;
  final List<Category> expenseCategories;
  final Map<String, String> walletNames;
  final Map<String, String> categoryNames;
  final DebtType? typeFilter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSaving;
  final String? loadError;
  final String? actionError;

  bool get hasMore => debts.length < total;

  List<Debt> get visibleDebts {
    if (typeFilter == null) return debts;
    return debts
        .where((debt) => debt.type == typeFilter)
        .toList(growable: false);
  }

  int get payableMinor => debts
      .where((debt) => debt.type == DebtType.payable && debt.canPay)
      .fold(0, (total, debt) => total + debt.remainingAmountMinor);

  int get receivableMinor => debts
      .where((debt) => debt.type == DebtType.receivable && debt.canPay)
      .fold(0, (total, debt) => total + debt.remainingAmountMinor);

  int get dueSoonCount => debts.where(_isDueSoon).length;

  int get paidMinor => debts
      .where((debt) => debt.status == DebtStatus.paidOff)
      .fold(0, (total, debt) => total + debt.paidAmountMinor);

  String walletName(String id) => walletNames[id] ?? 'Dompet tidak dikenal';

  String categoryName(String id) => categoryNames[id] ?? 'Tanpa kategori';

  List<Category> disbursementCategories(DebtType type) {
    return type == DebtType.payable ? incomeCategories : expenseCategories;
  }

  List<Category> paymentCategories(DebtType type) {
    return type == DebtType.payable ? expenseCategories : incomeCategories;
  }

  DebtState copyWith({
    List<Debt>? debts,
    int? total,
    List<Wallet>? wallets,
    List<Category>? incomeCategories,
    List<Category>? expenseCategories,
    Map<String, String>? walletNames,
    Map<String, String>? categoryNames,
    Object? typeFilter = kUnchanged,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSaving,
    Object? loadError = kUnchanged,
    Object? actionError = kUnchanged,
  }) {
    return DebtState(
      debts: debts ?? this.debts,
      total: total ?? this.total,
      wallets: wallets ?? this.wallets,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      walletNames: walletNames ?? this.walletNames,
      categoryNames: categoryNames ?? this.categoryNames,
      typeFilter: identical(typeFilter, kUnchanged)
          ? this.typeFilter
          : typeFilter as DebtType?,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSaving: isSaving ?? this.isSaving,
      loadError: identical(loadError, kUnchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, kUnchanged)
          ? this.actionError
          : actionError as String?,
    );
  }
}

bool _isDueSoon(Debt debt) {
  if (!debt.canPay || debt.dueDate == null || debt.dueDate!.isEmpty) {
    return false;
  }
  final dueDate = DateTime.tryParse(debt.dueDate!);
  if (dueDate == null) return false;
  // Shared local-day window: the old raw-instant comparison excluded debts
  // due exactly 7 days out in WIB and, with no lower bound, kept counting
  // overdue debts forever.
  return withinSevenDays(dueDate);
}
