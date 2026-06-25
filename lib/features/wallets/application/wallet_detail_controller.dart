import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/date_formatter.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';

/// Loads the wallet and its members in parallel. Analytics is fetched by a
/// separate provider so a slow or failing analytics call never takes down the
/// whole detail screen.
final walletDetailProvider = FutureProvider.family<WalletDetailState, String>((
  ref,
  walletId,
) async {
  final repository = ref.watch(walletRepositoryProvider);
  final results = await Future.wait([
    repository.getWallet(walletId),
    repository.listMembers(walletId),
  ]);

  return WalletDetailState(
    wallet: results[0] as Wallet,
    members: (results[1] as WalletMembersResponse).members,
  );
});

class WalletDetailState {
  const WalletDetailState({required this.wallet, required this.members});

  final Wallet wallet;
  final List<WalletMember> members;
}

/// The currently selected analytics month, keyed by wallet. Defaults to the
/// current month. Mutating this re-fetches [walletAnalyticsProvider] only.
final walletAnalyticsMonthProvider =
    NotifierProvider.family<WalletAnalyticsMonth, DateTime, String>(
      (walletId) => WalletAnalyticsMonth(),
    );

class WalletAnalyticsMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void select(DateTime month) {
    state = DateTime(month.year, month.month);
  }
}

/// Analytics for the wallet at the selected month. Isolated from the detail
/// provider so it can load, fail, and retry independently.
final walletAnalyticsProvider = FutureProvider.family<WalletAnalytics, String>((
  ref,
  walletId,
) async {
  final month = ref.watch(walletAnalyticsMonthProvider(walletId));
  final repository = ref.watch(walletRepositoryProvider);
  return repository.getAnalytics(
    walletId,
    month: AffluenaDateFormatter.monthKey(month),
  );
});
