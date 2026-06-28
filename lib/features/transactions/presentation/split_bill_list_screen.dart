import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../data/split_bill_models.dart';
import '../data/transaction_repository.dart';
import 'split_bill_screen.dart';

/// Lists the user's split bills (status: null = all, 'ongoing', 'settled').
final splitBillListProvider = FutureProvider.autoDispose
    .family<SplitBillListResponse, String?>((ref, status) {
      return ref
          .read(transactionRepositoryProvider)
          .listSplitBills(status: status);
    });

class SplitBillListScreen extends ConsumerStatefulWidget {
  const SplitBillListScreen({super.key});

  static const path = '/transactions/split';

  @override
  ConsumerState<SplitBillListScreen> createState() =>
      _SplitBillListScreenState();
}

class _SplitBillListScreenState extends ConsumerState<SplitBillListScreen> {
  // null = all, 'ongoing' = only unsettled.
  String? _status = 'ongoing';

  Future<void> _openCreate() async {
    await context.push(SplitBillScreen.path);
    // Refresh on return so a just-created split bill shows up in the list.
    if (mounted) ref.invalidate(splitBillListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final listing = ref.watch(splitBillListProvider(_status));

    return DrillInScaffold(
      title: 'Bagi tagihan',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('split-bill-create-fab'),
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Bagi baru'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8 + 64,
        ),
        children: [
          Wrap(
            spacing: AffluenaSpacing.space2,
            children: [
              ChoiceChip(
                showCheckmark: false,
                selected: _status == 'ongoing',
                label: const Text('Berjalan'),
                onSelected: (_) => setState(() => _status = 'ongoing'),
              ),
              ChoiceChip(
                showCheckmark: false,
                selected: _status == null,
                label: const Text('Semua'),
                onSelected: (_) => setState(() => _status = null),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          listing.when(
            skipLoadingOnReload: true,
            loading: () => const _SplitListSkeleton(),
            error: (error, _) => AffluenaBanner.error(
              'Kami tidak dapat memuat bagi tagihanmu.',
              onRetry: () => ref.invalidate(splitBillListProvider),
            ),
            data: (response) {
              final bills = response.splitBills;
              if (bills.isEmpty) {
                return _SplitListEmpty(status: _status, onCreate: _openCreate);
              }
              return Column(
                children: [
                  for (final bill in bills) ...[
                    _SplitBillCard(
                      bill: bill,
                      onTap: () => _openDetail(bill.transactionId),
                    ),
                    const SizedBox(height: AffluenaSpacing.space3),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(String transactionId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _SplitBillDetailSheet(transactionId: transactionId),
    );
  }
}

class _SplitBillCard extends StatelessWidget {
  const _SplitBillCard({required this.bill, required this.onTap});

  final SplitBillSummary bill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: onTap,
      child: AffluenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bill.note.isEmpty ? 'Bagi tagihan' : bill.note,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(
                  label: bill.isOngoing ? 'Berjalan' : 'Lunas',
                  tone: bill.isOngoing
                      ? StatusTone.warning
                      : StatusTone.success,
                ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(
              '${MoneyFormatter.idr(bill.totalAmountMinor)} · '
              '${bill.participantCount} orang · '
              '${AffluenaDateFormatter.shortDate(bill.transactionAt)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(
              bill.isOngoing
                  ? '${MoneyFormatter.idr(bill.totalRemainingMinor)} masih terutang kepadamu'
                  : 'Semua sudah membayar kamu',
              style: textTheme.bodyLarge?.copyWith(
                color: bill.isOngoing ? colors.forest : colors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitBillDetailSheet extends ConsumerWidget {
  const _SplitBillDetailSheet({required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final detail = ref.watch(_splitBillDetailProvider(transactionId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          0,
          AffluenaSpacing.space5,
          AffluenaSpacing.space5,
        ),
        child: detail.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AffluenaSpacing.space6),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AffluenaSpacing.space5,
            ),
            child: AffluenaBanner.error(
              'Kami tidak dapat memuat bagi tagihan ini.',
              onRetry: () =>
                  ref.invalidate(_splitBillDetailProvider(transactionId)),
            ),
          ),
          data: (d) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.note.isEmpty ? 'Bagi tagihan' : d.note,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space1),
              Text(
                '${MoneyFormatter.idr(d.totalAmountMinor)} total · '
                '${AffluenaDateFormatter.shortDate(d.transactionAt)}',
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              Text(
                d.isOngoing
                    ? '${MoneyFormatter.idr(d.totalRemainingMinor)} masih terutang kepadamu'
                    : 'Sudah lunas sepenuhnya',
                style: textTheme.bodyLarge?.copyWith(color: colors.forest),
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              Text('Peserta', style: textTheme.titleSmall),
              const SizedBox(height: AffluenaSpacing.space2),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: d.participants.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _ParticipantTile(participant: d.participants[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _splitBillDetailProvider = FutureProvider.autoDispose
    .family<SplitBillDetail, String>((ref, transactionId) {
      return ref
          .read(transactionRepositoryProvider)
          .getSplitBill(transactionId);
    });

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});

  final SplitBillParticipant participant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final paid = participant.status == 'paid_off';
    final cancelled = participant.status == 'cancelled';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.forestSoft,
            child: Text(
              _initial(participant.counterpartyName),
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
                  style: textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  paid
                      ? 'Lunas'
                      : cancelled
                      ? 'Dibatalkan'
                      : 'Sisa ${MoneyFormatter.idr(participant.remainingAmountMinor)} dari ${MoneyFormatter.idr(participant.principalAmountMinor)}',
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: paid
                ? 'Lunas'
                : cancelled
                ? 'Dibatalkan'
                : 'Berutang',
            tone: paid
                ? StatusTone.success
                : cancelled
                ? StatusTone.neutral
                : StatusTone.warning,
          ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}

class _SplitListSkeleton extends StatelessWidget {
  const _SplitListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          const AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AffluenaSkeleton.line(width: 160, height: 16),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton.line(width: 200),
                SizedBox(height: AffluenaSpacing.space2),
                AffluenaSkeleton.line(width: 140),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
      ],
    );
  }
}

class _SplitListEmpty extends StatelessWidget {
  const _SplitListEmpty({required this.status, required this.onCreate});

  final String? status;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      backgroundColor: colors.forestSoft,
      borderColor: colors.forestSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.call_split_outlined, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            status == 'ongoing'
                ? 'Tidak ada bagi tagihan yang berjalan'
                : 'Belum ada bagi tagihan',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Bagi tagihan dengan teman — kamu membayar di muka dan memantau '
            'berapa yang harus dibayar tiap orang kepadamu.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          FilledButton.icon(
            key: const Key('split-bill-empty-create'),
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Bagi tagihan baru'),
          ),
        ],
      ),
    );
  }
}
