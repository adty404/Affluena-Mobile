import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

/// A single-line, horizontally-scrolling strip of chips — the tidy layout used
/// by the Transaksi type filters. Use this instead of a [Wrap] for a row of
/// [AffluenaChoiceChip]s so they never wrap raggedly onto multiple lines.
class AffluenaChipBar extends StatelessWidget {
  const AffluenaChipBar({required this.chips, super.key});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: AffluenaSpacing.space2),
            chips[i],
          ],
        ],
      ),
    );
  }
}
