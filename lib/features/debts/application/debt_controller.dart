import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/debt_models.dart';
import '../data/debt_repository.dart';

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

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null, actionError: null);

    try {
      final debtsFuture = ref
          .read(debtRepositoryProvider)
          .listDebts(limit: debtPageSize, offset: 0, sort: 'opened_at_desc');
      final walletsFuture = ref
          .read(walletRepositoryProvider)
          .listWallets(limit: 100, offset: 0, sort: 'name_asc');
      final categoriesFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(limit: 100, offset: 0, sort: 'name_asc');

      final debtResponse = await debtsFuture;
      final walletResponse = await walletsFuture;
      final categoryResponse = await categoriesFuture;
      final selectableWallets = walletResponse.wallets
          .where((wallet) => !wallet.isGoal)
          .toList(growable: false);

      state = state.copyWith(
        isLoading: false,
        debts: debtResponse.debts,
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
        loadError: 'Debts could not be loaded.',
      );
    }
  }

  void setTypeFilter(DebtType? type) {
    if (state.typeFilter == type) return;
    state = state.copyWith(typeFilter: type);
  }

  Future<void> createDebt(DebtRequest request) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await ref.read(debtRepositoryProvider).createDebt(request);
      state = state.copyWith(isSaving: false);
      await load();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Debt could not be created.',
      );
    }
  }

  Future<void> updateDebt(Debt debt, DebtUpdateRequest request) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await ref.read(debtRepositoryProvider).updateDebt(debt.id, request);
      state = state.copyWith(isSaving: false);
      await load();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Debt could not be updated.',
      );
    }
  }

  Future<void> payDebt(Debt debt, DebtPaymentRequest request) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await ref.read(debtRepositoryProvider).payDebt(debt.id, request);
      state = state.copyWith(isSaving: false);
      await load();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Debt payment could not be recorded.',
      );
    }
  }

  Future<void> cancelDebt(Debt debt) async {
    await updateDebt(
      debt,
      DebtUpdateRequest(
        counterpartyName: debt.counterpartyName,
        dueDate: debt.dueDate,
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
  final bool isSaving;
  final String? loadError;
  final String? actionError;

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

  String walletName(String id) => walletNames[id] ?? 'Unknown wallet';

  String categoryName(String id) => categoryNames[id] ?? 'Uncategorized';

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
    Object? typeFilter = _unchanged,
    bool? isLoading,
    bool? isSaving,
    Object? loadError = _unchanged,
    Object? actionError = _unchanged,
  }) {
    return DebtState(
      debts: debts ?? this.debts,
      total: total ?? this.total,
      wallets: wallets ?? this.wallets,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      walletNames: walletNames ?? this.walletNames,
      categoryNames: categoryNames ?? this.categoryNames,
      typeFilter: identical(typeFilter, _unchanged)
          ? this.typeFilter
          : typeFilter as DebtType?,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      loadError: identical(loadError, _unchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, _unchanged)
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
  final today = DateTime.now();
  final end = DateTime(today.year, today.month, today.day + 7);
  return !dueDate.isAfter(end);
}

const _unchanged = Object();
