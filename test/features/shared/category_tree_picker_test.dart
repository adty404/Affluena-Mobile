import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/category_tree_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inline add creates the category and selects it immediately', (
    tester,
  ) async {
    final repository = _PickerCategoryRepository();
    String? pickedId;
    var mutations = 0;

    await tester.pumpWidget(
      _pickerTestApp(
        repository: repository,
        onOpen: (context) async {
          pickedId = await showCategoryTreePicker(
            context: context,
            title: 'Kategori',
            quickAdd: const CategoryQuickAdd(type: CategoryType.expense),
            onMutated: () async => mutations++,
            categories: const [
              CategoryTreeEntry(
                id: 'category-food',
                name: 'Food & Dining',
                type: CategoryType.expense,
              ),
            ],
          );
        },
      ),
    );

    await tester.tap(find.text('Buka picker'));
    await tester.pumpAndSettle();
    expect(find.text('Food & Dining'), findsOneWidget);

    // The pinned action opens the compact inline create form.
    await tester.tap(find.byKey(const Key('category-picker-add-button')));
    await tester.pumpAndSettle();
    // Type is preset from context, so no expense/income toggle is shown.
    expect(find.text('Pengeluaran'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('category-picker-name-field')),
      'Jajan',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('category-icon-food')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-icon-food')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('category-picker-save-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-picker-save-button')));
    await tester.pumpAndSettle();

    // Created with the preset type + chosen icon, refreshed the caller, and
    // the sheet popped with the fresh id selected.
    final request = repository.createdRequests.single;
    expect(request.name, 'Jajan');
    expect(request.type, CategoryType.expense);
    expect(request.icon, 'food');
    expect(mutations, 1);
    expect(pickedId, 'category-jajan');
    expect(find.byKey(const Key('category-picker-name-field')), findsNothing);
  });

  testWidgets('failed inline add stays on the form with an error', (
    tester,
  ) async {
    final repository = _PickerCategoryRepository()
      ..createError = Exception('boom');
    String? pickedId = 'sentinel';

    await tester.pumpWidget(
      _pickerTestApp(
        repository: repository,
        onOpen: (context) async {
          pickedId = await showCategoryTreePicker(
            context: context,
            title: 'Kategori',
            quickAdd: const CategoryQuickAdd(type: CategoryType.expense),
            categories: const [],
          );
        },
      ),
    );

    await tester.tap(find.text('Buka picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-picker-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('category-picker-name-field')),
      'Jajan',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('category-picker-save-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-picker-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Kategori gagal dibuat.'), findsOneWidget);
    expect(find.byKey(const Key('category-picker-name-field')), findsOneWidget);
    expect(pickedId, 'sentinel');
  });
}

Widget _pickerTestApp({
  required _PickerCategoryRepository repository,
  required Future<void> Function(BuildContext context) onOpen,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [categoryRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => onOpen(context),
              child: const Text('Buka picker'),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PickerCategoryRepository implements CategoryRepository {
  final createdRequests = <CategoryRequest>[];
  final reorderedIdLists = <List<String>>[];
  Object? createError;

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const CategoryListResponse(
      categories: [],
      pagination: Pagination(total: 0, limit: 0, offset: 0),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async {
    if (createError != null) throw createError!;
    createdRequests.add(request);
    return Category(
      id: 'category-${request.name.toLowerCase().replaceAll(' ', '-')}',
      userId: 'user-1',
      parentId: request.parentId,
      name: request.name,
      type: request.type,
      icon: request.icon ?? '',
      color: request.color ?? '',
      createdAt: '2026-07-01T00:00:00Z',
      updatedAt: '2026-07-01T00:00:00Z',
    );
  }

  @override
  Future<Category> getCategory(String id) async => throw UnimplementedError();

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<void> reorderCategories(List<String> ids) async {
    reorderedIdLists.add(List<String>.of(ids));
  }
}
