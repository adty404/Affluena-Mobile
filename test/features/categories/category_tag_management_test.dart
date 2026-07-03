import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/categories/presentation/category_tag_management_screen.dart';
import 'package:affluena_mobile/features/shared/presentation/appearance/item_appearance.dart';
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

    // Tree renders the parent, its child indented beneath it, and a child-count
    // hint on the parent — instead of a flat "Parent: X" subtitle.
    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('1 sub'), findsOneWidget);
    expect(find.text('Parent: Food & Dining'), findsNothing);
    expect(find.text(foodCategory.id), findsNothing);

    await tester.tap(find.byKey(const Key('add-category-button')));
    await tester.pumpAndSettle();
    expect(find.text('Buat kategori'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Restaurants',
    );
    // Pick an icon and a color from the appearance pickers.
    await tester.ensureVisible(find.byKey(const Key('category-icon-food')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-icon-food')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('category-color-#2E8B57')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('category-color-#2E8B57')),
      warnIfMissed: true,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tanpa induk'));
    await tester.tap(find.text('Tanpa induk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Dining').last);
    await tester.pumpAndSettle();

    expect(find.text('Food & Dining'), findsWidgets);
    expect(find.text(foodCategory.id), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('category-save-button')));
    await tester.tap(find.byKey(const Key('category-save-button')));
    await tester.pumpManagementState();

    expect(categoryRepository.createdRequests.single.name, 'Restaurants');
    expect(categoryRepository.createdRequests.single.parentId, foodCategory.id);
    expect(categoryRepository.createdRequests.single.icon, 'food');
    expect(categoryRepository.createdRequests.single.color, '#2E8B57');
    await tester.scrollUntilTextVisible('Restaurants');
    expect(find.text('Restaurants'), findsOneWidget);
    // Food now has two children rendered beneath it in the tree.
    expect(find.text('2 sub'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('category-menu-category-restaurants')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();
    expect(find.text('Ubah kategori'), findsOneWidget);
    expect(find.text('Food & Dining'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('category-name-field')),
      'Restaurants & Cafes',
    );
    await tester.ensureVisible(find.byKey(const Key('category-save-button')));
    await tester.tap(find.byKey(const Key('category-save-button')));
    await tester.pumpManagementState();

    expect(categoryRepository.updatedIds.single, 'category-restaurants');
    expect(categoryRepository.updatedRequests.single.parentId, foodCategory.id);
    expect(find.text('Restaurants & Cafes'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('category-menu-category-restaurants')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus kategori'));
    await tester.pumpManagementState();

    expect(categoryRepository.deletedIds.single, 'category-restaurants');
    expect(find.text('Restaurants & Cafes'), findsNothing);
  });

  testWidgets('renders the chosen category icon in its color on the row', (
    tester,
  ) async {
    final categoryRepository = TestCategoryManagementRepository(
      categories: const [paintedCategory, salaryCategory],
    );

    await tester.pumpWidget(
      categoryTagTestApp(categoryRepository: categoryRepository),
    );
    await tester.pumpManagementState();

    // The row carries the catalog glyph for icon id 'travel', tinted with the
    // stored color instead of the generic folder glyph.
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(ItemAccentIconTile),
        matching: find.byIcon(Icons.flight_outlined),
      ),
    );
    expect(icon.color, const Color(0xFF2E8B57));
  });

  testWidgets('drag-and-drop reorder persists the flattened order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final categoryRepository = TestCategoryManagementRepository(
      categories: const [
        foodCategory,
        coffeeCategory,
        salaryCategory,
        transportCategory,
      ],
    );

    await tester.pumpWidget(
      categoryTagTestApp(categoryRepository: categoryRepository),
    );
    await tester.pumpManagementState();

    // Expense roots render in list (position) order: Food before Transport.
    expect(
      tester.getTopLeft(find.text('Food & Dining')).dy,
      lessThan(tester.getTopLeft(find.text('Transport')).dy),
    );

    await tester.longPressDragCategory(
      from: find.text('Transport'),
      to: find.text('Food & Dining'),
    );

    // The whole loaded hierarchy is flattened back into one ordered id list:
    // income first, then the rearranged expense roots, children after their
    // parent.
    expect(categoryRepository.reorderedIdLists.single, [
      'category-salary',
      'category-transport',
      'category-food',
      'category-coffee',
    ]);
    // Optimistic UI: Transport now renders above Food.
    expect(
      tester.getTopLeft(find.text('Transport')).dy,
      lessThan(tester.getTopLeft(find.text('Food & Dining')).dy),
    );
  });

  testWidgets('failed reorder reverts the order and shows a snackbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final categoryRepository = TestCategoryManagementRepository(
      categories: const [
        foodCategory,
        coffeeCategory,
        salaryCategory,
        transportCategory,
      ],
    )..reorderError = Exception('boom');

    await tester.pumpWidget(
      categoryTagTestApp(categoryRepository: categoryRepository),
    );
    await tester.pumpManagementState();

    await tester.longPressDragCategory(
      from: find.text('Transport'),
      to: find.text('Food & Dining'),
    );

    expect(find.text('Urutan kategori gagal disimpan.'), findsOneWidget);
    expect(categoryRepository.reorderedIdLists, isEmpty);
    // Order reverted: Food is back above Transport.
    expect(
      tester.getTopLeft(find.text('Food & Dining')).dy,
      lessThan(tester.getTopLeft(find.text('Transport')).dy),
    );
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
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus kategori'));
    await tester.pumpManagementState();

    expect(find.text('Kategori gagal dihapus.'), findsOneWidget);
    await tester.scrollUntilTextVisible('Coffee');
    expect(find.text('Coffee'), findsOneWidget);
    expect(categoryRepository.deletedIds, isEmpty);

    categoryRepository.deleteError = null;
    await tester.tap(find.byKey(const Key('category-menu-category-coffee')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus kategori'));
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

  /// Simulates dragging the visible drag-handle (Icons.drag_indicator) of the
  /// [from] row to just above [to]. The handle uses ReorderableDragStartListener
  /// (immediate drag), so no long-press hold is needed — the drag starts on the
  /// handle belonging to [from] (the handle whose vertical center is nearest the
  /// row).
  Future<void> longPressDragCategory({
    required Finder from,
    required Finder to,
  }) async {
    final fromY = getCenter(from).dy;
    final handles = find.byIcon(Icons.drag_indicator);
    final count = handles.evaluate().length;
    var start = getCenter(from);
    var best = double.infinity;
    for (var i = 0; i < count; i++) {
      final c = getCenter(handles.at(i));
      if ((c.dy - fromY).abs() < best) {
        best = (c.dy - fromY).abs();
        start = c;
      }
    }
    final target = getTopLeft(to) - const Offset(0, 24);
    final gesture = await startGesture(start);
    await pump(const Duration(milliseconds: 20));
    // Move in steps so the drag recognizer tracks the pointer.
    final delta = Offset(0, (target.dy - start.dy) / 6);
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(delta);
      await pump(const Duration(milliseconds: 40));
    }
    await gesture.up();
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
  final reorderedIdLists = <List<String>>[];
  Object? listError;
  Object? deleteError;
  Object? reorderError;

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

  @override
  Future<void> reorderCategories(List<String> ids) async {
    if (reorderError != null) throw reorderError!;
    reorderedIdLists.add(List<String>.of(ids));
    // Mirror the API: listed ids take positions 0..n-1 (list order).
    _categories.sort((a, b) {
      final aIndex = ids.indexOf(a.id);
      final bIndex = ids.indexOf(b.id);
      return aIndex.compareTo(bIndex);
    });
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

const transportCategory = Category(
  id: 'category-transport',
  userId: 'user-1',
  name: 'Transport',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

/// A category with a chosen appearance: catalog icon 'travel' + green accent.
const paintedCategory = Category(
  id: 'category-travel',
  userId: 'user-1',
  name: 'Liburan',
  type: CategoryType.expense,
  icon: 'travel',
  color: '#2E8B57',
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
