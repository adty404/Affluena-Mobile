import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
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
      // No explicit sort: the API default is position ASC (the user-arranged
      // drag-and-drop order), name as tie-break.
      final categoryFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(limit: categoryTagPageSize, offset: 0);
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
        loadError: 'Kategori dan tag gagal dimuat.',
      );
    }
  }

  Future<void> loadMoreCategories() async {
    if (state.isLoading ||
        state.isLoadingMoreCategories ||
        !state.hasMoreCategories) {
      return;
    }
    state = state.copyWith(isLoadingMoreCategories: true, actionError: null);
    try {
      final response = await ref
          .read(categoryRepositoryProvider)
          .listCategories(
            limit: categoryTagPageSize,
            offset: state.categories.length,
          );
      state = state.copyWith(
        isLoadingMoreCategories: false,
        categories: [...state.categories, ...response.categories],
        categoryTotal: response.pagination.total,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMoreCategories: false,
        actionError: 'Kategori lainnya gagal dimuat.',
      );
    }
  }

  Future<void> loadMoreTags() async {
    if (state.isLoading || state.isLoadingMoreTags || !state.hasMoreTags) {
      return;
    }
    state = state.copyWith(isLoadingMoreTags: true, actionError: null);
    try {
      final response = await ref
          .read(tagRepositoryProvider)
          .listTags(
            limit: categoryTagPageSize,
            offset: state.tags.length,
            sort: 'name_asc',
          );
      state = state.copyWith(
        isLoadingMoreTags: false,
        tags: [...state.tags, ...response.tags],
        tagTotal: response.pagination.total,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMoreTags: false,
        actionError: 'Tag lainnya gagal dimuat.',
      );
    }
  }

  Future<bool> saveCategory({
    Category? category,
    required String name,
    required CategoryType type,
    String? parentId,
    String icon = '',
    String color = '',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(actionError: 'Nama kategori wajib diisi.');
      return false;
    }

    state = state.copyWith(isSaving: true, actionError: null);
    // Always send icon/color ('' = cleared) so removing an icon or picking
    // "no color" on edit actually clears the stored value.
    final request = CategoryRequest(
      name: trimmedName,
      type: type,
      parentId: parentId,
      icon: icon,
      color: color,
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
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        actionError: _categorySaveError(error, isCreate: category == null),
      );
      return false;
    }
  }

  /// Maps a failed category save to user-facing copy, surfacing the server's
  /// 3-level hierarchy limit inline rather than a generic failure.
  String _categorySaveError(Object error, {required bool isCreate}) {
    final apiError = error is DioException ? error.error : error;
    final message = apiError is ApiException
        ? apiError.message.toLowerCase()
        : '';
    if (message.contains('depth') || message.contains('3 level')) {
      return 'Kategori hanya bisa bertingkat 3 level. Pilih induk di level lebih atas.';
    }
    return isCreate ? 'Kategori gagal dibuat.' : 'Kategori gagal diperbarui.';
  }

  Future<void> deleteCategory(Category category) async {
    state = state.copyWith(actionError: null);
    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
      await load();
    } catch (_) {
      state = state.copyWith(actionError: 'Kategori gagal dihapus.');
    }
  }

  /// Persists a drag-and-drop rearrangement. [ordered] is the full loaded
  /// category list in its new order; the UI is updated optimistically and
  /// reverted when the API call fails. Returns false on failure so the caller
  /// can surface a SnackBar.
  Future<bool> reorderCategories(List<Category> ordered) async {
    final previous = state.categories;
    state = state.copyWith(
      categories: List<Category>.of(ordered),
      actionError: null,
    );
    try {
      await ref.read(categoryRepositoryProvider).reorderCategories([
        for (final category in ordered) category.id,
      ]);
      return true;
    } catch (_) {
      state = state.copyWith(categories: previous);
      return false;
    }
  }

  Future<bool> saveTag({Tag? tag, required String name}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(actionError: 'Nama tag wajib diisi.');
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
            ? 'Tag gagal dibuat.'
            : 'Tag gagal diperbarui.',
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
      state = state.copyWith(actionError: 'Tag gagal dihapus.');
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
    this.isLoadingMoreCategories = false,
    this.isLoadingMoreTags = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
  });

  /// Maximum nesting depth the backend allows (root + 2 descendants).
  static const maxCategoryDepth = 3;

  final List<Category> categories;
  final List<Tag> tags;
  final int categoryTotal;
  final int tagTotal;
  final bool isLoading;
  final bool isLoadingMoreCategories;
  final bool isLoadingMoreTags;
  final bool isSaving;
  final String? loadError;
  final String? actionError;

  bool get hasMoreCategories => categories.length < categoryTotal;

  bool get hasMoreTags => tags.length < tagTotal;

  String categoryName(String? id) {
    if (id == null) return 'Tanpa induk';
    for (final category in categories) {
      if (category.id == id) return category.name;
    }
    return 'Kategori tidak dikenal';
  }

  Category? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// Depth of [category] within the loaded hierarchy (a root category is 1).
  /// Guards against cycles in case of partial/inconsistent data.
  int depthOf(Category category) {
    var depth = 1;
    var current = category;
    final seen = <String>{current.id};
    while (current.parentId != null) {
      final parent = categoryById(current.parentId!);
      if (parent == null || !seen.add(parent.id)) break;
      depth += 1;
      current = parent;
    }
    return depth;
  }

  /// Whether a new child can be nested under [parent] without exceeding the
  /// backend's [maxCategoryDepth] limit. A parent already at the deepest
  /// allowed level cannot take children.
  bool canParent(Category parent) => depthOf(parent) < maxCategoryDepth;

  CategoryTagManagementState copyWith({
    List<Category>? categories,
    List<Tag>? tags,
    int? categoryTotal,
    int? tagTotal,
    bool? isLoading,
    bool? isLoadingMoreCategories,
    bool? isLoadingMoreTags,
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
      isLoadingMoreCategories:
          isLoadingMoreCategories ?? this.isLoadingMoreCategories,
      isLoadingMoreTags: isLoadingMoreTags ?? this.isLoadingMoreTags,
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
