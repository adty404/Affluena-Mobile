import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/theme_mode_controller.dart';
import 'settings_sheet_widgets.dart';

Future<void> showThemeSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ThemeSheet(),
  );
}

class _ThemeSheet extends ConsumerWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appThemeModeProvider);

    return SettingsSheetFrame(
      title: 'Appearance',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, mode) in ThemeMode.values.indexed) ...[
            _ThemeOption(
              mode: mode,
              selected: mode == current,
              onTap: () {
                ref.read(appThemeModeProvider.notifier).setMode(mode);
                Navigator.of(context).pop();
              },
            ),
            if (index != ThemeMode.values.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: mode.label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AffluenaRadii.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.forestSoft,
                    borderRadius: BorderRadius.circular(AffluenaRadii.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AffluenaSpacing.space2),
                    child: Icon(mode.icon, color: colors.forest, size: 20),
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space3),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mode.label, style: textTheme.bodyLarge),
                      const SizedBox(height: AffluenaSpacing.space1),
                      Text(
                        mode.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: colors.forest, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
