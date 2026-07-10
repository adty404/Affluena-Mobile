import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tracker_models.dart';
import '../data/tracker_repository.dart';

/// Payment history for one installment (`GET /installments/:id/payments`),
/// newest first. `autoDispose.family` so an open detail screen holds exactly
/// one live fetch; the bare family is listed in `_balanceProviders`
/// (financial_refresh.dart) so paying refreshes the open history in place.
final installmentPaymentsProvider = FutureProvider.autoDispose
    .family<List<InstallmentPayment>, String>((ref, id) async {
      final payments = await ref
          .watch(trackerRepositoryProvider)
          .listInstallmentPayments(id);
      // The API already orders paid_at DESC; sort defensively so the section
      // stays newest-first even if the backend ordering drifts.
      return [...payments]..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    });

/// Payment history for one subscription (`GET /subscriptions/:id/payments`),
/// newest first. Same lifecycle/refresh story as
/// [installmentPaymentsProvider].
final subscriptionPaymentsProvider = FutureProvider.autoDispose
    .family<List<SubscriptionPayment>, String>((ref, id) async {
      final payments = await ref
          .watch(trackerRepositoryProvider)
          .listSubscriptionPayments(id);
      return [...payments]..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    });
