import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tags/data/tag_models.dart';
import '../../tags/data/tag_repository.dart';
import '../data/category_models.dart';
import '../data/category_repository.dart';

const categoryTagPageSize = 100;

final categoryTagManagementControllerProvider =
    NotifierProvider<
      CategoryTagManagementController,
      CategoryTagManagementState
    >(CategoryTagManagementController.new);

class CategoryTagManagementController
    extends Notifier<CategoryTagManagementState> {
  @override
  CategoryTagManagementState build() {
    Future<void>.microtask(load);
    return const CategoryTagManagementState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null, actionError: null);

    try {
      final categoryFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(
            limit: categoryTagPageSize,
            offset: 0,
            sort: 'name_asc',
          );
      final tagFuture = ref
          .read(tagRepositoryProvider)
          .listTags(limit: categoryTagPageSize, offset: 0, sort: 'name_asc');

      final categoryResponse = await categoryFuture;
      final tagResponse = await tagFuture;

      state = state.copyWith(
        isLoading: false,
        categories: categoryResponse.categories,
        tags: tagResponse.tags,
        categoryTotal: categoryResponse.pagination.total,
        tagTotal: tagResponse.pagination.total,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Categories and tags could not be loaded.',
      );
    }
  }

  Future<bool> saveCategory({
    Category? category,
    required String name,
    required CategoryType type,
    String? parentId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(actionError: 'Category name is required.');
      return false;
    }

    state = state.copyWith(isSaving: true, actionError: null);
    final request = CategoryRequest(
      name: trimmedName,
      type: type,
      parentId: parentId,
    );

    try {
      if (category == null) {
        await ref.read(categoryRepositoryProvider).createCategory(request);
      } else {
        await ref
            .read(categoryRepositoryProvider)
            .updateCategory(category.id, request);
      }
      state = state.copyWith(isSaving: false);
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: category == null
            ? 'Category could not be created.'
            : 'Category could not be updated.',
      );
      return false;
    }
  }

  Future<void> deleteCategory(Category category) async {
    state = state.copyWith(actionError: null);
    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
      await load();
    } catch (_) {
      state = state.copyWith(actionError: 'Category could not be deleted.');
    }
  }

  Future<bool> saveTag({Tag? tag, required String name}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(actionError: 'Tag name is required.');
      return false;
    }

    state = state.copyWith(isSaving: true, actionError: null);
    final request = TagRequest(name: trimmedName);

    try {
      if (tag == null) {
        await ref.read(tagRepositoryProvider).createTag(request);
      } else {
        await ref.read(tagRepositoryProvider).updateTag(tag.id, request);
      }
      state = state.copyWith(isSaving: false);
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: tag == null
            ? 'Tag could not be created.'
            : 'Tag could not be updated.',
      );
      return false;
    }
  }

  Future<void> deleteTag(Tag tag) async {
    state = state.copyWith(actionError: null);
    try {
      await ref.read(tagRepositoryProvider).deleteTag(tag.id);
      await load();
    } catch (_) {
      state = state.copyWith(actionError: 'Tag could not be deleted.');
    }
  }
}

class CategoryTagManagementState {
  const CategoryTagManagementState({
    this.categories = const [],
    this.tags = const [],
    this.categoryTotal = 0,
    this.tagTotal = 0,
    this.isLoading = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
  });

  final List<Category> categories;
  final List<Tag> tags;
  final int categoryTotal;
  final int tagTotal;
  final bool isLoading;
  final bool isSaving;
  final String? loadError;
  final String? actionError;

  String categoryName(String? id) {
    if (id == null) return 'No parent';
    for (final category in categories) {
      if (category.id == id) return category.name;
    }
    return 'Unknown category';
  }

  Category? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  CategoryTagManagementState copyWith({
    List<Category>? categories,
    List<Tag>? tags,
    int? categoryTotal,
    int? tagTotal,
    bool? isLoading,
    bool? isSaving,
    Object? loadError = _unchanged,
    Object? actionError = _unchanged,
  }) {
    return CategoryTagManagementState(
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      categoryTotal: categoryTotal ?? this.categoryTotal,
      tagTotal: tagTotal ?? this.tagTotal,
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

const _unchanged = Object();
