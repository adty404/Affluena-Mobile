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
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AffluenaSpacing.space5,
                      ),
                      child: Text('No options found'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final selected = option.value == widget.selectedValue;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: option.icon == null
                              ? null
                              : Icon(option.icon, color: colors.forest),
                          title: Text(option.label),
                          subtitle: option.subtitle == null
                              ? null
                              : Text(option.subtitle!),
                          trailing: selected
                              ? Icon(Icons.check, color: colors.forest)
                              : null,
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
