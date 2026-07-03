import 'package:affluena_mobile/features/shared/presentation/appearance/item_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('entityIconFor', () {
    test('resolves category-catalog ids', () {
      expect(entityIconFor('food'), Icons.restaurant_outlined);
      expect(entityIconFor('salary'), Icons.payments_outlined);
    });

    test('resolves wallet-only catalog ids', () {
      expect(entityIconFor('bank'), Icons.account_balance_outlined);
      expect(entityIconFor('ewallet'), Icons.phone_iphone_outlined);
    });

    test('category catalog wins on an id clash', () {
      // 'investment' exists in both catalogs with different glyphs; the
      // category glyph must win so both clients resolve identically.
      expect(entityIconFor('investment'), Icons.show_chart);
      expect(
        entityIconFor('investment'),
        isNot(kWalletIconCatalog['investment']),
      );
    });

    test('returns null for empty or unknown ids', () {
      expect(entityIconFor(''), isNull);
      expect(entityIconFor('not-a-catalog-id'), isNull);
    });
  });

  group('resolveEntityIcon', () {
    test('prefers the stored id when known', () {
      expect(
        resolveEntityIcon('bank', Icons.pie_chart_outline),
        Icons.account_balance_outlined,
      );
    });

    test('falls back for empty or unknown ids', () {
      expect(
        resolveEntityIcon('', Icons.pie_chart_outline),
        Icons.pie_chart_outline,
      );
      expect(
        resolveEntityIcon('not-a-catalog-id', Icons.autorenew),
        Icons.autorenew,
      );
    });
  });
}
