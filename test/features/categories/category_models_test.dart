import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category.fromJson', () {
    test('parses icon, color, and position', () {
      final category = Category.fromJson(const {
        'id': 'category-food',
        'user_id': 'user-1',
        'parent_id': null,
        'name': 'Food & Dining',
        'type': 'expense',
        'icon': 'food',
        'color': '#2E8B57',
        'position': 3,
        'created_at': '2026-06-01T00:00:00Z',
        'updated_at': '2026-06-01T00:00:00Z',
      });

      expect(category.icon, 'food');
      expect(category.color, '#2E8B57');
      expect(category.position, 3);
    });

    test('defends against missing appearance fields with defaults', () {
      // Older payloads (or nulls) must not blank the screen: icon/color fall
      // back to '' and position to 0.
      final category = Category.fromJson(const {
        'id': 'category-food',
        'user_id': 'user-1',
        'parent_id': null,
        'name': 'Food & Dining',
        'type': 'expense',
        'created_at': '2026-06-01T00:00:00Z',
        'updated_at': '2026-06-01T00:00:00Z',
      });

      expect(category.icon, '');
      expect(category.color, '');
      expect(category.position, 0);
    });
  });

  group('CategoryRequest.toJson', () {
    test('round-trips icon and color', () {
      const request = CategoryRequest(
        name: 'Food & Dining',
        type: CategoryType.expense,
        parentId: 'category-parent',
        icon: 'food',
        color: '#2E8B57',
      );

      expect(request.toJson(), {
        'name': 'Food & Dining',
        'type': 'expense',
        'parent_id': 'category-parent',
        'icon': 'food',
        'color': '#2E8B57',
      });
    });

    test('omits appearance keys when unset, sends empty string to clear', () {
      const unset = CategoryRequest(name: 'Salary', type: CategoryType.income);
      expect(unset.toJson(), {'name': 'Salary', 'type': 'income'});

      const cleared = CategoryRequest(
        name: 'Salary',
        type: CategoryType.income,
        icon: '',
        color: '',
      );
      expect(cleared.toJson(), {
        'name': 'Salary',
        'type': 'income',
        'icon': '',
        'color': '',
      });
    });
  });
}
