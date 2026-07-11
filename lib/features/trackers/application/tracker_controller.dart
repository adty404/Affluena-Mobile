import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/calc/due_window.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/haptics.dart';
import '../../../core/state/copy_with_sentinel.dart';
import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../shared/application/financial_refresh.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/tracker_models.dart';
import '../data/tracker_repository.dart';

const trackerPageSize = 20;

final trackerControllerProvider =
    NotifierProvider<TrackerController, TrackerState>(TrackerController.new);

class TrackerController extends Notifier<TrackerState> {
  @override
  TrackerState build() {
    Future<void>.microtask(load);
    return const TrackerState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null, actionError: null);

    try {
      final installmentsFuture = ref
          .read(trackerRepositoryProvider)
          .listInstallments(
            limit: trackerPageSize,
            offset: 0,
            sort: 'created_at_desc',
          );
      final subscriptionsFuture = ref
          .read(trackerRepositoryProvider)
          .listSubscriptions(
            limit: trackerPageSize,
            offset: 0,
            sort: 'next_due_date_asc',
          );
      final walletsFuture = ref
          .read(walletRepositoryProvider)
          .listWallets(limit: 100, offset: 0, sort: 'name_asc');
      final categoriesFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(type: CategoryType.expense, limit: 100, offset: 0);

      final installmentsResponse = await installmentsFuture;
      final subscriptionsResponse = await subscriptionsFuture;
      final walletsResponse = await walletsFuture;
      final categoriesResponse = await categoriesFuture;
      final selectableWallets = walletsResponse.wallets
          .where((wallet) => !wallet.isGoal)
          .toList(growable: false);

      state = state.copyWith(
        isLoading: false,
        installments: installmentsResponse.installments,
        installmentTotal: installmentsResponse.pagination.total,
        subscriptions: subscriptionsResponse.subscriptions,
        subscriptionTotal: subscriptionsResponse.pagination.total,
        wallets: selectableWallets,
        categories: categoriesResponse.categories,
        walletNames: {
          for (final wallet in selectableWallets) wallet.id: wallet.name,
        },
        categoryNames: {
          for (final category in categoriesResponse.categories)
            category.id: category.name,
        },
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Cicilan & Langganan gagal dimuat.',
      );
    }
  }

  void setTab(TrackerTab tab) {
    if (state.tab == tab) return;
    state = state.copyWith(tab: tab);
  }

  Future<void> createInstallment(InstallmentRequest request) async {
    await _save(
      () => ref.read(trackerRepositoryProvider).createInstallment(request),
    );
  }

  Future<void> updateInstallment(
    Installment installment,
    InstallmentRequest request,
  ) async {
    await _save(
      () => ref
          .read(trackerRepositoryProvider)
          .updateInstallment(installment.id, request),
    );
  }

  Future<void> payInstallment(
    Installment installment,
    TrackerPaymentRequest request,
  ) async {
    await _save(
      () => ref
          .read(trackerRepositoryProvider)
          .payInstallment(installment.id, request),
      errorMessage: 'Pembayaran cicilan gagal dicatat.',
    );
    // _save swallows failures into actionError; only a clean run buzzes.
    if (state.actionError == null) hapticSuccess();
  }

  Future<void> cancelInstallment(Installment installment) async {
    await updateInstallment(
      installment,
      InstallmentRequest(
        name: installment.name,
        walletId: installment.walletId,
        categoryId: installment.categoryId,
        totalAmountMinor: installment.totalAmountMinor,
        monthlyAmountMinor: installment.monthlyAmountMinor,
        tenorMonths: installment.tenorMonths,
        remainingMonths: installment.remainingMonths,
        // The stored value is a full RFC3339 timestamp, but start_date is a
        // strict date-only API field — re-sending it raw 400s.
        startDate: AffluenaDateFormatter.apiDate(installment.startDate),
        dueDay: installment.dueDay,
        status: InstallmentStatus.cancelled,
        note: installment.note,
        // Re-send the stored appearance so the cancel preserves it.
        color: installment.color,
        icon: installment.icon,
      ),
    );
  }

  Future<void> deleteInstallment(Installment installment) async {
    await _save(
      () =>
          ref.read(trackerRepositoryProvider).deleteInstallment(installment.id),
      errorMessage: 'Cicilan gagal dihapus.',
    );
  }

  Future<void> createSubscription(SubscriptionRequest request) async {
    await _save(
      () => ref.read(trackerRepositoryProvider).createSubscription(request),
    );
  }

  Future<void> updateSubscription(
    Subscription subscription,
    SubscriptionRequest request,
  ) async {
    await _save(
      () => ref
          .read(trackerRepositoryProvider)
          .updateSubscription(subscription.id, request),
    );
  }

  Future<void> paySubscription(
    Subscription subscription,
    TrackerPaymentRequest request,
  ) async {
    await _save(
      () => ref
          .read(trackerRepositoryProvider)
          .paySubscription(subscription.id, request),
      errorMessage: 'Pembayaran langganan gagal dicatat.',
    );
    // _save swallows failures into actionError; only a clean run buzzes.
    if (state.actionError == null) hapticSuccess();
  }

  Future<void> deleteSubscription(Subscription subscription) async {
    await _save(
      () => ref
          .read(trackerRepositoryProvider)
          .deleteSubscription(subscription.id),
      errorMessage: 'Langganan gagal dihapus.',
    );
  }

  Future<void> setSubscriptionStatus(
    Subscription subscription,
    SubscriptionStatus status,
  ) async {
    await updateSubscription(
      subscription,
      SubscriptionRequest(
        name: subscription.name,
        accountDetail: subscription.accountDetail,
        walletId: subscription.walletId,
        categoryId: subscription.categoryId,
        amountMinor: subscription.amountMinor,
        billingCycle: subscription.billingCycle,
        // The stored value is a full RFC3339 timestamp, but next_due_date is a
        // strict date-only API field — re-sending it raw 400s and the pause/
        // resume button silently does nothing.
        nextDueDate: AffluenaDateFormatter.apiDate(subscription.nextDueDate),
        status: status,
        note: subscription.note,
        // Re-send the stored appearance so the status change preserves it.
        color: subscription.color,
        icon: subscription.icon,
      ),
    );
  }

  Future<void> _save(
    Future<Object?> Function() action, {
    String errorMessage = 'Cicilan & Langganan gagal disimpan.',
  }) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await action();
      ref.invalidateFinancialData();
      state = state.copyWith(isSaving: false);
      await load();
    } catch (_) {
      state = state.copyWith(isSaving: false, actionError: errorMessage);
    }
  }
}

enum TrackerTab { installments, subscriptions }

class TrackerState {
  const TrackerState({
    this.tab = TrackerTab.installments,
    this.installments = const [],
    this.installmentTotal = 0,
    this.subscriptions = const [],
    this.subscriptionTotal = 0,
    this.wallets = const [],
    this.categories = const [],
    this.walletNames = const {},
    this.categoryNames = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
  });

  final TrackerTab tab;
  final List<Installment> installments;
  final int installmentTotal;
  final List<Subscription> subscriptions;
  final int subscriptionTotal;
  final List<Wallet> wallets;
  final List<Category> categories;
  final Map<String, String> walletNames;
  final Map<String, String> categoryNames;
  final bool isLoading;
  final bool isSaving;
  final String? loadError;
  final String? actionError;

  int get installmentMonthlyMinor => installments
      .where((item) => item.status == InstallmentStatus.active)
      .fold(0, (total, item) => total + item.monthlyAmountMinor);

  int get subscriptionMonthlyMinor => subscriptions
      .where(
        (item) =>
            item.status == SubscriptionStatus.active &&
            item.billingCycle == BillingCycle.monthly,
      )
      .fold(0, (total, item) => total + item.amountMinor);

  int get weeklySubscriptionMinor => subscriptions
      .where(
        (item) =>
            item.status == SubscriptionStatus.active &&
            item.billingCycle == BillingCycle.weekly,
      )
      .fold(0, (total, item) => total + item.amountMinor);

  int get dueSoonCount =>
      subscriptions.where(_subscriptionDueSoon).length +
      installments.where(_installmentDueSoon).length;

  String walletName(String id) => walletNames[id] ?? 'Dompet tidak dikenal';

  String categoryName(String id) => categoryNames[id] ?? 'Tanpa kategori';

  TrackerState copyWith({
    TrackerTab? tab,
    List<Installment>? installments,
    int? installmentTotal,
    List<Subscription>? subscriptions,
    int? subscriptionTotal,
    List<Wallet>? wallets,
    List<Category>? categories,
    Map<String, String>? walletNames,
    Map<String, String>? categoryNames,
    bool? isLoading,
    bool? isSaving,
    Object? loadError = kUnchanged,
    Object? actionError = kUnchanged,
  }) {
    return TrackerState(
      tab: tab ?? this.tab,
      installments: installments ?? this.installments,
      installmentTotal: installmentTotal ?? this.installmentTotal,
      subscriptions: subscriptions ?? this.subscriptions,
      subscriptionTotal: subscriptionTotal ?? this.subscriptionTotal,
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      walletNames: walletNames ?? this.walletNames,
      categoryNames: categoryNames ?? this.categoryNames,
      isLoading: isLoading ?? this.isLoading,
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

bool _subscriptionDueSoon(Subscription item) {
  if (!item.canPay) return false;
  final due = DateTime.tryParse(item.nextDueDate);
  if (due == null) return false;
  return withinSevenDays(due);
}

bool _installmentDueSoon(Installment item) {
  if (!item.canPay) return false;
  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  // This month's occurrence, with the due day clamped to the month's length so
  // a dueDay of 31 in a short month doesn't overflow into the next month.
  var due = _installmentOccurrence(today.year, today.month, item.dueDay);
  // If this month's occurrence already passed, roll to next month's (wrapping
  // December → January) — the installment isn't overdue-forever, it recurs.
  if (due.isBefore(todayMidnight)) {
    final nextMonth = today.month == 12 ? 1 : today.month + 1;
    final nextYear = today.month == 12 ? today.year + 1 : today.year;
    due = _installmentOccurrence(nextYear, nextMonth, item.dueDay);
  }
  return withinSevenDays(due);
}

/// The installment's due date in [year]/[month], with [dueDay] clamped to the
/// month's last day (mirrors `installment_detail_screen.dart`'s schedule build).
DateTime _installmentOccurrence(int year, int month, int dueDay) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, dueDay.clamp(1, lastDay));
}
