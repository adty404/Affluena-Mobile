import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/debt_detail_controller.dart';
import '../data/debt_models.dart';

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({required this.debtId, super.key});

  static const path = '/debts/:debtId';

  static String location(String debtId) => '/debts/$debtId';

  final String debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(debtDetailProvider(debtId));

    return DrillInScaffold(
      title: detail.value?.counterpartyName ?? 'Debt detail',
      body: detail.when(
        skipLoadingOnReload: true,
        loading: () => const _DebtDetailSkeleton(),
        error: (error, stackTrace) => _DebtDetailError(
          onRetry: () => ref.invalidate(debtDetailProvider(debtId)),
        ),
        data: (debt) => _DebtDetailContent(debt: debt),
      ),
    );
  }
}

class _DebtDetailContent extends StatelessWidget {
  const _DebtDetailContent({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final isPayable = debt.type == DebtType.payable;
    final accent = isPayable ? colors.coral : colors.success;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AffluenaSpacing.space5,
        AffluenaSpacing.space4,
        AffluenaSpacing.space5,
        AffluenaSpacing.space8,
      ),
      children: [
        AffluenaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      debt.counterpartyName,
                      style: textTheme.headlineSmall,
                    ),
                  ),
                  StatusBadge.forStatus(
                    debt.status.apiValue,
                    label: debt.status.label,
                  ),
                ],
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              StatusBadge(
                label: isPayable ? 'Payable' : 'Receivable',
                tone: isPayable ? StatusTone.danger : StatusTone.success,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              Text(
                MoneyFormatter.idr(debt.remainingAmountMinor),
                style: textTheme.displaySmall,
              ),
              const SizedBox(height: AffluenaSpacing.space1),
              Text(
                '${debt.paidPercent.round()}% settled of '
                '${MoneyFormatter.idr(debt.principalAmountMinor)}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              ClipRRect(
                borderRadius: BorderRadius.circular(AffluenaRadii.pill),
                child: LinearProgressIndicator(
                  value: debt.paidPercent / 100,
                  minHeight: 10,
                  color: accent,
                  backgroundColor: colors.surfaceTintSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space5),
        AffluenaCard(
          child: Column(
            children: [
              Row(
                children: [
                  MetricTile(
                    label: 'Principal',
                    value: MoneyFormatter.idr(debt.principalAmountMinor),
                    helper: 'Original amount',
                    icon: Icons.account_balance_outlined,
                  ),
                  const SizedBox(width: AffluenaSpacing.space3),
                  MetricTile(
                    label: 'Paid',
                    value: MoneyFormatter.idr(debt.paidAmountMinor),
                    helper: 'Settled so far',
                    icon: Icons.done_all,
                  ),
                ],
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              _DetailRow(
                icon: Icons.event_outlined,
                title: 'Opened',
                value: AffluenaDateFormatter.shortDate(debt.openedAt),
              ),
              const Divider(height: 1),
              _DetailRow(
                icon: Icons.schedule_outlined,
                title: 'Due date',
                value: debt.dueDate == null || debt.dueDate!.isEmpty
                    ? 'No due date'
                    : AffluenaDateFormatter.shortDate(debt.dueDate!),
              ),
              if (debt.note.isNotEmpty) ...[
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.notes_outlined,
                  title: 'Note',
                  value: debt.note,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space6),
        SectionHeader(
          title: 'Payment history',
          actionLabel: debt.payments.isEmpty
              ? null
              : debt.payments.length == 1
              ? '1 payment'
              : '${debt.payments.length} payments',
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        if (debt.payments.isEmpty)
          const _EmptyPayments()
        else
          _PaymentTimeline(payments: debt.payments, accent: accent),
      ],
    );
  }
}

class _PaymentTimeline extends StatelessWidget {
  const _PaymentTimeline({required this.payments, required this.accent});

  final List<DebtPayment> payments;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        children: [
          for (final (index, payment) in payments.indexed)
            _TimelineEntry(
              payment: payment,
              accent: accent,
              isFirst: index == 0,
              isLast: index == payments.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.payment,
    required this.accent,
    required this.isFirst,
    required this.isLast,
  });

  final DebtPayment payment;
  final Color accent;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : colors.borderSubtle,
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : colors.borderSubtle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AffluenaSpacing.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          MoneyFormatter.idr(payment.amountMinor),
                          style: textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        AffluenaDateFormatter.shortDate(payment.paidAt),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (payment.note.isNotEmpty) ...[
                    const SizedBox(height: AffluenaSpacing.space1),
                    Text(payment.note, style: textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.forest, size: 20),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(child: Text(title, style: textTheme.bodyMedium)),
          const SizedBox(width: AffluenaSpacing.space3),
          Flexible(
            child: Text(
              value,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  const _EmptyPayments();

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
          Icon(Icons.receipt_long_outlined, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('No payments yet', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Recorded payments will appear here as a timeline.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DebtDetailSkeleton extends StatelessWidget {
  const _DebtDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AffluenaSkeleton.line(width: 160, height: 20),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton.line(width: 96, height: 14),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(width: 200, height: 32),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton(height: 10, radius: AffluenaRadii.pill),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: Column(
              children: [
                AffluenaSkeleton(height: 56),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton.line(),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton.line(width: 220),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const AffluenaSkeleton.line(width: 140, height: 16),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Row(
                    children: const [
                      AffluenaSkeleton.circle(size: 12),
                      SizedBox(width: AffluenaSpacing.space3),
                      Expanded(child: AffluenaSkeleton.line()),
                    ],
                  ),
                  if (i != 2) const SizedBox(height: AffluenaSpacing.space4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtDetailError extends StatelessWidget {
  const _DebtDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          AffluenaBanner.error(
            'We could not load this debt.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}
