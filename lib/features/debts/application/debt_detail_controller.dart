import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/debt_models.dart';
import '../data/debt_repository.dart';

/// Loads a single debt (with its embedded payment history) from
/// `GET /debts/:id`. Sorted newest-payment-first for the detail timeline.
final debtDetailProvider = FutureProvider.family<Debt, String>((
  ref,
  debtId,
) async {
  final debt = await ref.watch(debtRepositoryProvider).getDebt(debtId);
  final payments = [...debt.payments]
    ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
  return Debt(
    id: debt.id,
    userId: debt.userId,
    type: debt.type,
    counterpartyName: debt.counterpartyName,
    walletId: debt.walletId,
    disbursementCategoryId: debt.disbursementCategoryId,
    paymentCategoryId: debt.paymentCategoryId,
    originationTransactionId: debt.originationTransactionId,
    principalAmountMinor: debt.principalAmountMinor,
    paidAmountMinor: debt.paidAmountMinor,
    remainingAmountMinor: debt.remainingAmountMinor,
    openedAt: debt.openedAt,
    status: debt.status,
    note: debt.note,
    createdAt: debt.createdAt,
    updatedAt: debt.updatedAt,
    dueDate: debt.dueDate,
    payments: payments,
  );
});
