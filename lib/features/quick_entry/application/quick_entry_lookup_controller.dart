import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../quick_entry/data/quick_entry_models.dart';
import '../../quick_entry/data/quick_entry_repository.dart';
import '../../tags/data/tag_models.dart';
import '../../tags/data/tag_repository.dart';
import '../../transactions/data/transaction_models.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';

final quickEntryLookupProvider = FutureProvider<QuickEntryLookup>((ref) async {
  final walletRepository = ref.watch(walletRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);
  final quickEntryRepository = ref.watch(quickEntryRepositoryProvider);

  final walletsFuture = walletRepository.listWallets(
    limit: 100,
    offset: 0,
    sort: 'name_asc',
  );
  final expenseCategoriesFuture = categoryRepository.listCategories(
    type: CategoryType.expense,
    limit: 100,
    offset: 0,
  );
  final incomeCategoriesFuture = categoryRepository.listCategories(
    type: CategoryType.income,
    limit: 100,
    offset: 0,
  );
  final tagsFuture = tagRepository.listTags(
    limit: 100,
    offset: 0,
    sort: 'name_asc',
  );
  final templatesFuture = quickEntryRepository.listTemplates(
    limit: 20,
    offset: 0,
    sort: 'name_asc',
  );

  final wallets = await walletsFuture;
  final expenseCategories = await expenseCategoriesFuture;
  final incomeCategories = await incomeCategoriesFuture;
  final tags = await tagsFuture;
  final templates = await templatesFuture;

  return QuickEntryLookup(
    // Only wallets the user can write to are selectable (and auto-defaulted).
    wallets: wallets.wallets.where((w) => w.canWrite).toList(growable: false),
    expenseCategories: expenseCategories.categories,
    incomeCategories: incomeCategories.categories,
    tags: tags.tags,
    templates: templates.templates,
  );
});

class QuickEntryLookup {
  const QuickEntryLookup({
    required this.wallets,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.tags,
    required this.templates,
  });

  final List<Wallet> wallets;
  final List<Category> expenseCategories;
  final List<Category> incomeCategories;
  final List<Tag> tags;
  final List<QuickEntryTemplate> templates;

  bool get canSaveExpense => wallets.isNotEmpty && expenseCategories.isNotEmpty;

  Wallet? walletById(String? id) => _findById(wallets, id);

  Category? categoryById(TransactionType type, String? id) {
    return _findById(categoriesFor(type), id);
  }

  Tag? tagById(String? id) => _findById(tags, id);

  Wallet? get defaultWallet {
    return _preferredByName(wallets, 'GoPay') ??
        (wallets.isEmpty ? null : wallets.first);
  }

  Category? get defaultExpenseCategory {
    return _preferredByName(expenseCategories, 'Food & Dining') ??
        (expenseCategories.isEmpty ? null : expenseCategories.first);
  }

  Category? get defaultIncomeCategory {
    return _preferredByName(incomeCategories, 'Salary') ??
        (incomeCategories.isEmpty ? null : incomeCategories.first);
  }

  Tag? get defaultTag {
    return _preferredByName(tags, '#MonthlyBill') ??
        (tags.isEmpty ? null : tags.first);
  }

  List<Category> categoriesFor(TransactionType type) {
    return switch (type) {
      TransactionType.income => incomeCategories,
      TransactionType.expense => expenseCategories,
      TransactionType.transfer || TransactionType.adjustment => const [],
    };
  }

  Category? defaultCategoryFor(TransactionType type) {
    return switch (type) {
      TransactionType.income => defaultIncomeCategory,
      TransactionType.expense => defaultExpenseCategory,
      TransactionType.transfer || TransactionType.adjustment => null,
    };
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
