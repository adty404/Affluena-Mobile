import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/category_tree_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('picker is selection-only: lists categories, no inline add', (
    tester,
  ) async {
    String? pickedId = 'sentinel';

    await tester.pumpWidget(
      _pickerTestApp(
        onOpen: (context) async {
          pickedId = await showCategoryTreePicker(
            context: context,
            title: 'Kategori',
            categories: const [
              CategoryTreeEntry(
                id: 'category-food',
                name: 'Food & Dining',
                type: CategoryType.expense,
              ),
              CategoryTreeEntry(
                id: 'category-transport',
                name: 'Transport',
                type: CategoryType.expense,
              ),
            ],
          );
        },
      ),
    );

    await tester.tap(find.text('Buka picker'));
    await tester.pumpAndSettle();

    // The categories render in the order they were passed (API position order).
    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);

    // CRUD moved to the dedicated management screen — the header exposes a
    // "Kelola kategori" gear and there is no inline "Tambah kategori" action.
    expect(
      find.byKey(const Key('category-picker-manage-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('category-picker-add-button')), findsNothing);
    expect(find.text('Tambah kategori'), findsNothing);

    // Tapping a category pops the sheet with that id.
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    expect(pickedId, 'category-transport');
  });

  testWidgets('search filters the visible categories', (tester) async {
    await tester.pumpWidget(
      _pickerTestApp(
        onOpen: (context) async {
          await showCategoryTreePicker(
            context: context,
            title: 'Kategori',
            categories: const [
              CategoryTreeEntry(
                id: 'category-food',
                name: 'Food & Dining',
                type: CategoryType.expense,
              ),
              CategoryTreeEntry(
                id: 'category-transport',
                name: 'Transport',
                type: CategoryType.expense,
              ),
            ],
          );
        },
      ),
    );

    await tester.tap(find.text('Buka picker'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('category-tree-search-field')),
      'trans',
    );
    await tester.pumpAndSettle();

    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Food & Dining'), findsNothing);
  });
}

Widget _pickerTestApp({
  required Future<void> Function(BuildContext context) onOpen,
}) {
  return ProviderScope(
    retry: noProviderRetry,
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
