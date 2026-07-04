import 'package:affluena_mobile/features/categories/application/category_tag_management_controller.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id, {String? parentId}) => Category(
  id: id,
  userId: 'u1',
  name: id,
  type: CategoryType.expense,
  parentId: parentId,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

void main() {
  group('CategoryTagManagementState depth math', () {
    // root → mid → leaf (a 3-level chain, the deepest the backend allows).
    final root = _cat('root');
    final mid = _cat('mid', parentId: 'root');
    final leaf = _cat('leaf', parentId: 'mid');
    final state = CategoryTagManagementState(categories: [root, mid, leaf]);

    test(
      'subtreeHeight counts the node itself plus its deepest descendant',
      () {
        expect(state.subtreeHeight(leaf), 1); // leaf only
        expect(state.subtreeHeight(mid), 2); // mid → leaf
        expect(state.subtreeHeight(root), 3); // root → mid → leaf
      },
    );

    test(
      'canReparent blocks a move that would push a grandchild to level 4',
      () {
        // Moving `mid` (height 2) under `leaf` (depth 3) would make its child a
        // level-4 category — rejected. canParent alone would wrongly allow it if
        // `leaf` had room, but here it also fails since leaf is at max depth.
        expect(state.canReparent(leaf, mid), isFalse);
      },
    );

    test('canReparent allows a move that keeps the subtree within max depth', () {
      // A fresh sibling subtree: newRoot → newChild (height 2). Moving it under
      // `root` (depth 1) yields depth 1 + height 2 = 3 ≤ max, so it's allowed.
      final newRoot = _cat('nr');
      final newChild = _cat('nc', parentId: 'nr');
      final s = CategoryTagManagementState(
        categories: [root, mid, leaf, newRoot, newChild],
      );
      expect(s.canReparent(root, newRoot), isTrue);
    });

    test('a leaf being re-parented reduces to canParent (height 1)', () {
      // `leaf` has height 1, so canReparent under `root` (depth 1) → 1 + 1 = 2,
      // which matches "can this depth-1 parent take a new child".
      expect(state.canReparent(root, leaf), state.canParent(root));
      expect(state.canReparent(root, leaf), isTrue);
    });

    test('subtreeHeight is cycle-guarded against inconsistent data', () {
      // Two nodes each claiming the other as parent must not recurse forever.
      final a = _cat('a', parentId: 'b');
      final b = _cat('b', parentId: 'a');
      final s = CategoryTagManagementState(categories: [a, b]);
      expect(s.subtreeHeight(a), greaterThanOrEqualTo(1));
      expect(s.subtreeHeight(b), greaterThanOrEqualTo(1));
    });
  });
}
