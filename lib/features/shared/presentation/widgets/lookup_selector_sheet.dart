import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

class LookupSelectorOption<T> {
  const LookupSelectorOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

Future<T?> showLookupSelectorSheet<T>({
  required BuildContext context,
  required String title,
  required List<LookupSelectorOption<T>> options,
  T? selectedValue,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      return LookupSelectorSheet<T>(
        title: title,
        options: options,
        selectedValue: selectedValue,
      );
    },
  );
}

class LookupSelectorSheet<T> extends StatefulWidget {
  const LookupSelectorSheet({
    required this.title,
    required this.options,
    this.selectedValue,
    super.key,
  });

  final String title;
  final List<LookupSelectorOption<T>> options;
  final T? selectedValue;

  @override
  State<LookupSelectorSheet<T>> createState() => _LookupSelectorSheetState<T>();
}

class _LookupSelectorSheetState<T> extends State<LookupSelectorSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxListHeight = (screenHeight * 0.5).clamp(280.0, 420.0);
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = widget.options
        .where((option) {
          if (normalizedQuery.isEmpty) return true;
          final label = option.label.toLowerCase();
          final subtitle = option.subtitle?.toLowerCase() ?? '';
          return label.contains(normalizedQuery) ||
              subtitle.contains(normalizedQuery);
        })
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AffluenaSpacing.space5,
          right: AffluenaSpacing.space5,
          bottom:
              MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: textTheme.titleLarge),
            const SizedBox(height: AffluenaSpacing.space4),
            TextField(
              key: const Key('lookup-search-field'),
              autocorrect: false,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AffluenaSpacing.space5,
                      ),
                      child: Center(
                        child: Text(
                          'No options found',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        bottom: AffluenaSpacing.space2,
                      ),
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AffluenaSpacing.space2),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final selected = option.value == widget.selectedValue;
                        return _LookupSelectorOptionTile<T>(
                          option: option,
                          selected: selected,
                          onTap: () => Navigator.of(context).pop(option.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LookupSelectorOptionTile<T> extends StatelessWidget {
  const _LookupSelectorOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final LookupSelectorOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final radius = BorderRadius.circular(AffluenaRadii.lg);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.forestSoft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? colors.forest : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AffluenaSpacing.space3,
                vertical: AffluenaSpacing.space2,
              ),
              child: Row(
                children: [
                  if (option.icon != null) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceTintSoft,
                        borderRadius: BorderRadius.circular(AffluenaRadii.md),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AffluenaSpacing.space2),
                        child: Icon(
                          option.icon,
                          color: colors.forest,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AffluenaSpacing.space3),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge,
                        ),
                        if (option.subtitle != null) ...[
                          const SizedBox(height: AffluenaSpacing.space1),
                          Text(
                            option.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: AffluenaSpacing.space3),
                    Icon(Icons.check_circle, color: colors.forest, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
