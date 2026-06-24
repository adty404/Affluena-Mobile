import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../tags/data/tag_models.dart';

/// Opens a multi-select sheet for choosing zero or more tags. Returns the new
/// list of selected tag ids, or `null` if the user dismissed without applying.
///
/// Mirrors [LookupSelectorSheet] visually (search + scrollable list + checked
/// rows) but supports multiple selections, which the single-value lookup sheet
/// cannot express. Lives in the quick-entry feature because that is the only
/// surface whose model exposes a `tagIds` list today.
Future<List<String>?> showTagMultiSelectSheet({
  required BuildContext context,
  required List<Tag> tags,
  required List<String> selectedIds,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) =>
        _TagMultiSelectSheet(tags: tags, selectedIds: selectedIds),
  );
}

class _TagMultiSelectSheet extends StatefulWidget {
  const _TagMultiSelectSheet({required this.tags, required this.selectedIds});

  final List<Tag> tags;
  final List<String> selectedIds;

  @override
  State<_TagMultiSelectSheet> createState() => _TagMultiSelectSheetState();
}

class _TagMultiSelectSheetState extends State<_TagMultiSelectSheet> {
  late final Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedIds};
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxListHeight = (screenHeight * 0.5).clamp(280.0, 420.0);
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = widget.tags
        .where(
          (tag) =>
              normalizedQuery.isEmpty ||
              tag.name.toLowerCase().contains(normalizedQuery),
        )
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Select tags', style: textTheme.titleLarge),
                ),
                if (_selected.isNotEmpty)
                  TextButton(
                    key: const Key('tag-multi-select-clear'),
                    onPressed: () => setState(_selected.clear),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            TextField(
              key: const Key('tag-multi-select-search'),
              autocorrect: false,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search tags',
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
                          'No tags found',
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
                        final tag = filtered[index];
                        final selected = _selected.contains(tag.id);
                        return _TagOptionTile(
                          label: _tagLabel(tag.name),
                          selected: selected,
                          onTap: () => setState(() {
                            if (selected) {
                              _selected.remove(tag.id);
                            } else {
                              _selected.add(tag.id);
                            }
                          }),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton(
              key: const Key('tag-multi-select-apply'),
              onPressed: () => Navigator.of(context).pop(
                // Preserve the original ordering of the source list.
                [
                  for (final tag in widget.tags)
                    if (_selected.contains(tag.id)) tag.id,
                ],
              ),
              child: Text(
                _selected.isEmpty
                    ? 'Use no tags'
                    : 'Apply ${_selected.length} ${_selected.length == 1 ? 'tag' : 'tags'}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagOptionTile extends StatelessWidget {
  const _TagOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceTintSoft,
                      borderRadius: BorderRadius.circular(AffluenaRadii.md),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(AffluenaSpacing.space2),
                      child: Icon(Icons.sell_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(width: AffluenaSpacing.space3),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? colors.forest : colors.inkMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _tagLabel(String name) {
  final normalized = name.trim().replaceFirst(RegExp(r'^#+'), '');
  return normalized.isEmpty ? '#' : '#$normalized';
}
