import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../tags/data/tag_models.dart';
import '../../tags/data/tag_repository.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';

final quickEntryLookupProvider = FutureProvider<QuickEntryLookup>((ref) async {
  final walletRepository = ref.watch(walletRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);

  final walletsFuture = walletRepository.listWallets(
    limit: 100,
    offset: 0,
    sort: 'name_asc',
  );
  final categoriesFuture = categoryRepository.listCategories(
    type: CategoryType.expense,
    limit: 100,
    offset: 0,
    sort: 'name_asc',
  );
  final tagsFuture = tagRepository.listTags(
    limit: 100,
    offset: 0,
    sort: 'name_asc',
  );

  final wallets = await walletsFuture;
  final categories = await categoriesFuture;
  final tags = await tagsFuture;

  return QuickEntryLookup(
    wallets: wallets.wallets,
    expenseCategories: categories.categories,
    tags: tags.tags,
  );
});

class QuickEntryLookup {
  const QuickEntryLookup({
    required this.wallets,
    required this.expenseCategories,
    required this.tags,
  });

  final List<Wallet> wallets;
  final List<Category> expenseCategories;
  final List<Tag> tags;

  bool get canSaveExpense => wallets.isNotEmpty && expenseCategories.isNotEmpty;

  Wallet? walletById(String? id) => _findById(wallets, id);

  Category? categoryById(String? id) => _findById(expenseCategories, id);

  Tag? tagById(String? id) => _findById(tags, id);

  Wallet? get defaultWallet {
    return _preferredByName(wallets, 'GoPay') ??
        (wallets.isEmpty ? null : wallets.first);
  }

  Category? get defaultExpenseCategory {
    return _preferredByName(expenseCategories, 'Food & Dining') ??
        (expenseCategories.isEmpty ? null : expenseCategories.first);
  }

  Tag? get defaultTag {
    return _preferredByName(tags, '#MonthlyBill') ??
        (tags.isEmpty ? null : tags.first);
  }
}

T? _preferredByName<T>(Iterable<T> items, String name) {
  final normalized = name.toLowerCase();
  for (final item in items) {
    final itemName = switch (item) {
      Wallet(:final name) => name,
      Category(:final name) => name,
      Tag(:final name) => name,
      _ => '',
    };
    if (itemName.toLowerCase() == normalized) return item;
  }
  return null;
}

T? _findById<T>(Iterable<T> items, String? id) {
  if (id == null) return null;
  for (final item in items) {
    final itemId = switch (item) {
      Wallet(:final id) => id,
      Category(:final id) => id,
      Tag(:final id) => id,
      _ => null,
    };
    if (itemId == id) return item;
  }
  return null;
}
