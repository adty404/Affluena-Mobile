import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';

final walletListProvider = FutureProvider<List<Wallet>>((ref) async {
  final response = await ref
      .watch(walletRepositoryProvider)
      .listWallets(limit: 100, offset: 0, sort: 'name_asc');
  return response.wallets;
});
