import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/tag_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../shared/application/financial_refresh.dart';
import '../../tags/data/tag_models.dart';
import '../../tags/data/tag_repository.dart';
import '../../transactions/data/transaction_models.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/quick_entry_models.dart';
import '../data/quick_entry_repository.dart';
import 'quick_entry_lookup_controller.dart';

const quickEntryTemplatePageSize = 100;

final quickEntryTemplatesControllerProvider =
    NotifierProvider<QuickEntryTemplatesController, QuickEntryTemplatesState>(
      QuickEntryTemplatesController.new,
    );

class QuickEntryTemplatesController extends Notifier<QuickEntryTemplatesState> {
  @override
  QuickEntryTemplatesState build() {
    Future<void>.microtask(load);
    return const QuickEntryTemplatesState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null, actionError: null);

    try {
      final walletFuture = ref
          .read(walletRepositoryProvider)
          .listWallets(
            limit: quickEntryTemplatePageSize,
            offset: 0,
            sort: 'name_asc',
          );
      final expenseCategoryFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(
            type: CategoryType.expense,
            limit: quickEntryTemplatePageSize,
            offset: 0,
            sort: 'name_asc',
          );
      final incomeCategoryFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(
            type: CategoryType.income,
            limit: quickEntryTemplatePageSize,
            offset: 0,
            sort: 'name_asc',
          );
      final tagFuture = ref
          .read(tagRepositoryProvider)
          .listTags(
            limit: quickEntryTemplatePageSize,
            offset: 0,
            sort: 'name_asc',
          );
      final templateFuture = ref
          .read(quickEntryRepositoryProvider)
          .listTemplates(
            limit: quickEntryTemplatePageSize,
            offset: 0,
            sort: 'name_asc',
          );

      final wallets = await walletFuture;
      final expenseCategories = await expenseCategoryFuture;
      final incomeCategories = await incomeCategoryFuture;
      final tags = await tagFuture;
      final templates = await templateFuture;

      state = state.copyWith(
        isLoading: false,
        wallets: wallets.wallets,
        expenseCategories: expenseCategories.categories,
        incomeCategories: incomeCategories.categories,
        tags: tags.tags,
        templates: templates.templates,
        total: templates.pagination.total,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Quick-entry templates could not be loaded.',
      );
    }
  }

  Future<bool> saveTemplate({
    QuickEntryTemplate? template,
    required QuickEntryTemplateRequest request,
  }) async {
    if (!_isValidTemplateRequest(request)) {
      state = state.copyWith(
        actionError: 'Complete the required template fields.',
        message: null,
      );
      return false;
    }

    state = state.copyWith(isSaving: true, actionError: null, message: null);
    try {
      if (template == null) {
        await ref.read(quickEntryRepositoryProvider).createTemplate(request);
      } else {
        await ref
            .read(quickEntryRepositoryProvider)
            .updateTemplate(template.id, request);
      }
      ref.invalidate(quickEntryLookupProvider);
      state = state.copyWith(isSaving: false);
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: template == null
            ? 'Template could not be created.'
            : 'Template could not be updated.',
      );
      return false;
    }
  }

  void clearMessage() {
    if (state.message == null) return;
    state = state.copyWith(message: null);
  }

  Future<void> deleteTemplate(QuickEntryTemplate template) async {
    state = state.copyWith(actionError: null, message: null);
    try {
      await ref.read(quickEntryRepositoryProvider).deleteTemplate(template.id);
      ref.invalidate(quickEntryLookupProvider);
      await load();
    } catch (_) {
      state = state.copyWith(actionError: 'Template could not be deleted.');
    }
  }

  Future<bool> executeTemplate(
    QuickEntryTemplate template,
    ExecuteQuickEntryRequest request,
  ) async {
    state = state.copyWith(isSaving: true, actionError: null, message: null);
    try {
      await ref
          .read(quickEntryRepositoryProvider)
          .executeTemplate(template.id, request);
      ref.invalidateFinancialData();
      state = state.copyWith(
        isSaving: false,
        message: '${template.name} recorded.',
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Template could not be executed.',
      );
      return false;
    }
  }
}

class QuickEntryTemplatesState {
  const QuickEntryTemplatesState({
    this.wallets = const [],
    this.expenseCategories = const [],
    this.incomeCategories = const [],
    this.tags = const [],
    this.templates = const [],
    this.total = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
    this.message,
  });

  final List<Wallet> wallets;
  final List<Category> expenseCategories;
  final List<Category> incomeCategories;
  final List<Tag> tags;
  final List<QuickEntryTemplate> templates;
  final int total;
  final bool isLoading;
  final bool isSaving;
  final String? loadError;
  final String? actionError;
  final String? message;

  List<Category> get allCategories => [
    ...expenseCategories,
    ...incomeCategories,
  ];

  List<Category> categoriesFor(TransactionType type) {
    return switch (type) {
      TransactionType.expense => expenseCategories,
      TransactionType.income => incomeCategories,
      TransactionType.transfer || TransactionType.adjustment => const [],
    };
  }

  Wallet? walletById(String? id) => _findById(wallets, id);

  Category? categoryById(String? id) => _findById(allCategories, id);

  Tag? tagById(String? id) => _findById(tags, id);

  String walletName(String? id) => walletById(id)?.name ?? 'Unknown wallet';

  String categoryName(String? id) {
    if (id == null) return 'No category';
    return categoryById(id)?.name ?? 'Unknown category';
  }

  String tagNames(List<String> ids) {
    if (ids.isEmpty) return 'No tags';
    final names = [
      for (final id in ids)
        if (tagById(id) case final tag?) tagLabel(tag.name),
    ];
    return names.isEmpty ? 'Unknown tags' : names.join(', ');
  }

  QuickEntryTemplatesState copyWith({
    List<Wallet>? wallets,
    List<Category>? expenseCategories,
    List<Category>? incomeCategories,
    List<Tag>? tags,
    List<QuickEntryTemplate>? templates,
    int? total,
    bool? isLoading,
    bool? isSaving,
    Object? loadError = _unchanged,
    Object? actionError = _unchanged,
    Object? message = _unchanged,
  }) {
    return QuickEntryTemplatesState(
      wallets: wallets ?? this.wallets,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      tags: tags ?? this.tags,
      templates: templates ?? this.templates,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      loadError: identical(loadError, _unchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, _unchanged)
          ? this.actionError
          : actionError as String?,
      message: identical(message, _unchanged)
          ? this.message
          : message as String?,
    );
  }
}

bool _isValidTemplateRequest(QuickEntryTemplateRequest request) {
  if (request.name.trim().isEmpty) return false;
  if (request.walletId.isEmpty) return false;
  if (request.amountMinor <= 0) return false;
  if (request.type == TransactionType.transfer) {
    return request.toWalletId != null &&
        request.toWalletId!.isNotEmpty &&
        request.toWalletId != request.walletId;
  }
  if (request.type == TransactionType.expense ||
      request.type == TransactionType.income) {
    return request.categoryId != null && request.categoryId!.isNotEmpty;
  }
  return true;
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

const _unchanged = Object();
