import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';

final walletDetailProvider = FutureProvider.family<WalletDetailState, String>((
  ref,
  walletId,
) async {
  final repository = ref.watch(walletRepositoryProvider);
  final wallet = await repository.getWallet(walletId);
  final members = await repository.listMembers(walletId);
  final analytics = await repository.getAnalytics(
    walletId,
    month: _currentMonth(DateTime.now()),
  );

  return WalletDetailState(
    wallet: wallet,
    members: members.members,
    analytics: analytics,
  );
});

class WalletDetailState {
  const WalletDetailState({
    required this.wallet,
    required this.members,
    required this.analytics,
  });

  final Wallet wallet;
  final List<WalletMember> members;
  final WalletAnalytics analytics;
}

String _currentMonth(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';
}
