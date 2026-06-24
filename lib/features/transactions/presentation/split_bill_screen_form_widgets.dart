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
          Text('Tags', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AffluenaSpacing.space2),
          Wrap(
            spacing: AffluenaSpacing.space2,
            runSpacing: AffluenaSpacing.space2,
            children: [
              ChoiceChip(
                key: const Key('split-tag-chip-none'),
                label: const Text('Optional'),
                selected: selectedTagId == null,
                onSelected: enabled ? (_) => onChanged(null) : null,
              ),
              for (final tag in tags)
                ChoiceChip(
                  key: Key('split-tag-chip-${tag.id}'),
                  label: Text(_tagLabel(tag.name)),
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
      'Record one expense and create receivable debts in the same flow.',
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
                  label: 'Total bill',
                  value: MoneyFormatter.idr(totalAmount),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: _MetricTile(
                  label: 'Your share',
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
                  label: 'Participant share',
                  value: MoneyFormatter.idr(participantTotal),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: _MetricTile(
                  label: 'Participants',
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
    required this.onAdd,
    required this.onRemove,
  });

  final List<SplitBillParticipantDraft> participants;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  participants.isEmpty
                      ? 'No participants added yet.'
                      : 'Receivable debt per participant',
                  style: textTheme.bodyMedium,
                ),
              ),
              IconButton.filledTonal(
                key: const Key('split-add-participant-button'),
                onPressed: onAdd,
                tooltip: 'Add participant',
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (participants.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            for (final entry in participants.indexed) ...[
              _ParticipantRow(
                participant: entry.$2,
                onRemove: onRemove == null ? null : () => onRemove!(entry.$1),
              ),
              if (entry.$1 < participants.length - 1) const Divider(height: 1),
            ],
          ],
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant, required this.onRemove});

  final SplitBillParticipantDraft participant;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.counterpartyName,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(
                  MoneyFormatter.idr(participant.amountMinor),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove participant',
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

