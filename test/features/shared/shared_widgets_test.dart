import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/selector_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'disabled selector row keeps touch size without action affordance',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AffluenaTheme.light,
          home: Material(
            child: SizedBox(
              width: 320,
              child: SelectorRow(
                label: 'Wallet',
                value: 'Cash account',
                icon: Icons.account_balance_wallet_outlined,
                enabled: false,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(56),
      );
    },
  );
}
