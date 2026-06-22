import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/categories/presentation/category_tag_management_screen.dart';
import 'package:affluena_mobile/features/tags/data/tag_models.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creates edits and deletes a child category by parent name', (
    tester,
  ) async {
    final categoryRepository = TestCategoryManagementRepository();

    await tester.pumpWidget(
      categoryTagTestApp(categoryRepository: categoryRepository),
    );
    await tester.pumpManagementState();

    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Parent: Food & Dining'), findsOneWidget);
    expect(find.text(foodCategory.id), findsNothing);

    await tester.tap(find.byKey(const Key('add-category-button')));
    await tester.pumpAndSettle();
    expect(find.text('Create category'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Restaurants',
    );
    await tester.tap(find.text('No parent'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Dining').last);
    await tester.pumpAndSettle();

    expect(find.text('Food & Dining'), findsWidgets);
    expect(find.text(foodCategory.id), findsNothing);

    await tester.tap(find.byKey(const Key('category-save-button')));
    await tester.pumpManagementState();

    expect(categoryRepository.createdRequests.single.name, 'Restaurants');
    expect(categoryRepository.createdRequests.single.parentId, foodCategory.id);
    await tester.scrollUntilTextVisible('Restaurants');
    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.text('Parent: Food & Dining'), findsWidgets);

    await tester.tap(
      find.byKey(const Key('category-menu-category-restaurants')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit category'), findsOneWidget);
    expect(find.text('Food & Dining'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Restaurants & Cafes',
    );
    await tester.tap(find.byKey(const Key('category-save-button')));
    await tester.pumpManagementState();

    expect(categoryRepository.updatedIds.single, 'category-restaurants');
    expect(categoryRepository.updatedRequests.single.parentId, foodCategory.id);
    expect(find.text('Restaurants & Cafes'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('category-menu-category-restaurants')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete category'));
    await tester.pumpManagementState();

    expect(categoryRepository.deletedIds.single, 'category-restaurants');
    expect(find.text('Restaurants & Cafes'), findsNothing);
  });

  testWidgets('creates edits and deletes a tag without showing raw ids', (
    tester,
  ) async {
    final tagRepository = TestTagManagementRepository();

    await tester.pumpWidget(categoryTagTestApp(tagRepository: tagRepository));
    await tester.pumpManagementState();

    await tester.tap(find.byKey(const Key('add-tag-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tag-name-field')), 'Weekend');
    await tester.pump();
    await tester.tap(find.byKey(const Key('tag-save-button')));
    await tester.pumpManagementState();

    expect(tagRepository.createdRequests.single.name, 'Weekend');
    await tester.scrollUntilTextVisible('#MonthlyBill');
    expect(find.text('#MonthlyBill'), findsOneWidget);
    expect(find.text(monthlyTag.id), findsNothing);
    await tester.scrollUntilTextVisible('#Weekend');
    expect(find.text('#Weekend'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tag-menu-tag-weekend')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('tag-name-field')), 'Family');
    await tester.pump();
    await tester.tap(find.byKey(const Key('tag-save-button')));
    await tester.pumpManagementState();

    expect(tagRepository.updatedIds.single, 'tag-weekend');
    expect(tagRepository.updatedRequests.single.name, 'Family');
    await tester.scrollUntilTextVisible('#Family');
    expect(find.text('#Family'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tag-menu-tag-weekend')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete tag'));
    await tester.pumpManagementState();

    expect(tagRepository.deletedIds.single, 'tag-weekend');
    expect(find.text('#Family'), findsNothing);
  });

  testWidgets('delete category error keeps list state and allows retry', (
    tester,
  ) async {
    final categoryRepository = TestCategoryManagementRepository()
      ..deleteError = Exception('conflict');

    await tester.pumpWidget(
      categoryTagTestApp(categoryRepository: categoryRepository),
    );
    await tester.pumpManagementState();

    await tester.tap(find.byKey(const Key('category-menu-category-coffee')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete category'));
    await tester.pumpManagementState();

    expect(find.text('Category could not be deleted.'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(categoryRepository.deletedIds, isEmpty);

    categoryRepository.deleteError = null;
    await tester.tap(find.byKey(const Key('category-menu-category-coffee')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete category'));
    await tester.pumpManagementState();

    expect(categoryRepository.deletedIds.single, 'category-coffee');
    expect(find.text('Coffee'), findsNothing);
  });
}

extension on WidgetTester {
  Future<void> pumpManagementState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }

  Future<void> scrollUntilTextVisible(String text) async {
    final finder = find.text(text);
    if (finder.evaluate().isNotEmpty) return;
    await scrollUntilVisible(
      finder,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpAndSettle();
  }
}

Widget categoryTagTestApp({
  TestCategoryManagementRepository? categoryRepository,
  TestTagManagementRepository? tagRepository,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      categoryRepositoryProvider.overrideWithValue(
        categoryRepository ?? TestCategoryManagementRepository(),
      ),
      tagRepositoryProvider.overrideWithValue(
        tagRepository ?? TestTagManagementRepository(),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: CategoryTagManagementScreen()),
    ),
  );
}

class TestCategoryManagementRepository implements CategoryRepository {
  TestCategoryManagementRepository({
    List<Category> categories = const [
      foodCategory,
      coffeeCategory,
      salaryCategory,
    ],
    this.listError,
  }) : _categories = List<Category>.of(categories);

  final List<Category> _categories;
  final createdRequests = <CategoryRequest>[];
  final updatedIds = <String>[];
  final updatedRequests = <CategoryRequest>[];
  final deletedIds = <String>[];
  Object? listError;
  Object? deleteError;

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    if (listError != null) throw listError!;
    final filtered = type == null
        ? _categories
        : _categories.where((category) => category.type == type).toList();
    return CategoryListResponse(
      categories: filtered,
      pagination: Pagination(
        total: filtered.length,
        limit: limit ?? filtered.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async {
    createdRequests.add(request);
    final category = Category(
      id: 'category-${request.name.toLowerCase().replaceAll(' ', '-')}',
      userId: 'user-1',
      parentId: request.parentId,
      name: request.name,
      type: request.type,
      createdAt: '2026-06-01T00:00:00Z',
      updatedAt: '2026-06-01T00:00:00Z',
    );
    _categories.add(category);
    return category;
  }

  @override
  Future<Category> getCategory(String id) async {
    return _categories.firstWhere((category) => category.id == id);
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    updatedIds.add(id);
    updatedRequests.add(request);
    final index = _categories.indexWhere((category) => category.id == id);
    final current = _categories[index];
    final category = Category(
      id: current.id,
      userId: current.userId,
      parentId: request.parentId,
      name: request.name,
      type: request.type,
      createdAt: current.createdAt,
      updatedAt: '2026-06-02T00:00:00Z',
    );
    _categories[index] = category;
    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (deleteError != null) throw deleteError!;
    deletedIds.add(id);
    _categories.removeWhere((category) => category.id == id);
  }
}

class TestTagManagementRepository implements TagRepository {
  TestTagManagementRepository({List<Tag> tags = const [monthlyTag]})
    : _tags = List<Tag>.of(tags);

  final List<Tag> _tags;
  final createdRequests = <TagRequest>[];
  final updatedIds = <String>[];
  final updatedRequests = <TagRequest>[];
  final deletedIds = <String>[];

  @override
  Future<TagListResponse> listTags({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return TagListResponse(
      tags: _tags,
      pagination: Pagination(
        total: _tags.length,
        limit: limit ?? _tags.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Tag> createTag(TagRequest request) async {
    createdRequests.add(request);
    final tag = Tag(
      id: 'tag-${request.name.toLowerCase()}',
      userId: 'user-1',
      name: request.name,
      createdAt: '2026-06-01T00:00:00Z',
      updatedAt: '2026-06-01T00:00:00Z',
    );
    _tags.add(tag);
    return tag;
  }

  @override
  Future<Tag> getTag(String id) async {
    return _tags.firstWhere((tag) => tag.id == id);
  }

  @override
  Future<Tag> updateTag(String id, TagRequest request) async {
    updatedIds.add(id);
    updatedRequests.add(request);
    final index = _tags.indexWhere((tag) => tag.id == id);
    final current = _tags[index];
    final tag = Tag(
      id: current.id,
      userId: current.userId,
      name: request.name,
      createdAt: current.createdAt,
      updatedAt: '2026-06-02T00:00:00Z',
    );
    _tags[index] = tag;
    return tag;
  }

  @override
  Future<void> deleteTag(String id) async {
    deletedIds.add(id);
    _tags.removeWhere((tag) => tag.id == id);
  }
}

const foodCategory = Category(
  id: 'category-food',
  userId: 'user-1',
  name: 'Food & Dining',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const coffeeCategory = Category(
  id: 'category-coffee',
  userId: 'user-1',
  parentId: 'category-food',
  name: 'Coffee',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const salaryCategory = Category(
  id: 'category-salary',
  userId: 'user-1',
  name: 'Salary',
  type: CategoryType.income,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const monthlyTag = Tag(
  id: 'tag-monthly',
  userId: 'user-1',
  name: '#MonthlyBill',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
