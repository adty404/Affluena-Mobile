part of 'split_bill_screen.dart';

class _SplitTagChips extends StatelessWidget {
  const _SplitTagChips({
    required this.tags,
    required this.selectedTagId,
    required this.enabled,
    required this.onChanged,
  });

  final List<Tag> tags;
  final String? selectedTagId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tag', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AffluenaSpacing.space2),
          Wrap(
            spacing: AffluenaSpacing.space2,
            runSpacing: AffluenaSpacing.space2,
            children: [
              ChoiceChip(
                key: const Key('split-tag-chip-none'),
                label: const Text('Opsional'),
                selected: selectedTagId == null,
                onSelected: enabled ? (_) => onChanged(null) : null,
              ),
              for (final tag in tags)
                ChoiceChip(
                  key: Key('split-tag-chip-${tag.id}'),
                  label: Text(tagLabel(tag.name)),
                  selected: selectedTagId == tag.id,
                  onSelected: enabled ? (_) => onChanged(tag.id) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitBillIntro extends StatelessWidget {
  const _SplitBillIntro();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      'Catat satu pengeluaran dan buat catatan piutang dalam satu alur.',
      style: textTheme.bodySmall,
    );
  }
}

class _SplitSummary extends StatelessWidget {
  const _SplitSummary({
    required this.totalAmount,
    required this.participantTotal,
    required this.userShare,
    required this.participantCount,
  });

  final int totalAmount;
  final int participantTotal;
  final int userShare;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      backgroundColor: context.affluenaColors.forestSoft,
      borderColor: context.affluenaColors.forestSoft,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Total tagihan',
                  value: MoneyFormatter.idr(totalAmount),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: _MetricTile(
                  label: 'Bagianmu',
                  value: MoneyFormatter.idr(userShare < 0 ? 0 : userShare),
                ),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Bagian peserta',
                  value: MoneyFormatter.idr(participantTotal),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: _MetricTile(
                  label: 'Peserta',
                  value: '$participantCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: AffluenaSpacing.space1),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}

class _ParticipantList extends StatelessWidget {
  const _ParticipantList({
    required this.participants,
    required this.totalAmountMinor,
    required this.onAdd,
    required this.onRemove,
  });

  final List<SplitBillParticipantDraft> participants;
  final int totalAmountMinor;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (participants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AffluenaSpacing.space3,
              ),
              child: Column(
                children: [
                  Icon(Icons.group_add_outlined, color: colors.inkMuted),
                  const SizedBox(height: AffluenaSpacing.space2),
                  Text(
                    'Tambahkan orang-orang yang membagi tagihan ini denganmu.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            for (final entry in participants.indexed) ...[
              _ParticipantRow(
                participant: entry.$2,
                sharePercent: totalAmountMinor > 0
                    ? entry.$2.amountMinor / totalAmountMinor * 100
                    : null,
                onRemove: onRemove == null ? null : () => onRemove!(entry.$1),
              ),
              if (entry.$1 < participants.length - 1) const Divider(height: 1),
            ],
          const SizedBox(height: AffluenaSpacing.space3),
          OutlinedButton.icon(
            key: const Key('split-add-participant-button'),
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Tambah peserta'),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.participant,
    required this.sharePercent,
    required this.onRemove,
  });

  final SplitBillParticipantDraft participant;
  final double? sharePercent;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final name = participant.counterpartyName.trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space2),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.forestSoft,
            child: Text(
              initial,
              style: textTheme.labelLarge?.copyWith(color: colors.forest),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.counterpartyName,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(
                  sharePercent == null
                      ? MoneyFormatter.idr(participant.amountMinor)
                      : '${MoneyFormatter.idr(participant.amountMinor)} · ${sharePercent!.round()}%',
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus peserta',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline, color: colors.coral),
          ),
        ],
      ),
    );
  }
}
