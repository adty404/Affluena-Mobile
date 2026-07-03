import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/appearance/item_appearance.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/date_picker_field.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/tracker_controller.dart';
import '../data/tracker_models.dart';

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key});

  static const path = '/trackers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerControllerProvider);
    final controller = ref.read(trackerControllerProvider.notifier);

    if (state.isLoading &&
        state.installments.isEmpty &&
        state.subscriptions.isEmpty) {
      return const _TrackerLoading();
    }

    if (state.loadError != null &&
        state.installments.isEmpty &&
        state.subscriptions.isEmpty) {
      return _TrackerError(onRetry: controller.load);
    }

    return DrillInScaffold(
      title: 'Cicilan & Langganan',
      actions: [
        IconButton.filledTonal(
          onPressed:
              state.wallets.isEmpty ||
                  state.categories.isEmpty ||
                  state.isSaving
              ? null
              : () => _showTrackerForm(context, state),
          icon: const Icon(Icons.add),
        ),
      ],
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          _TrackerSummaryCard(state: state),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            AffluenaBanner.error(state.actionError!, onRetry: controller.load),
            const SizedBox(height: AffluenaSpacing.space4),
          ],
          _TrackerTabs(selected: state.tab, onChanged: controller.setTab),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.tab == TrackerTab.installments)
            _InstallmentList(state: state, controller: controller)
          else
            _SubscriptionList(state: state, controller: controller),
        ],
      ),
    );
  }
}

class _TrackerSummaryCard extends StatelessWidget {
  const _TrackerSummaryCard({required this.state});

  final TrackerState state;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        children: [
          Row(
            children: [
              MetricTile(
                label: 'Cicilan',
                value: MoneyFormatter.idr(state.installmentMonthlyMinor),
                helper: 'Jatuh tempo bulanan',
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Langganan',
                value: MoneyFormatter.idr(state.subscriptionMonthlyMinor),
                helper: 'Bulanan',
                icon: Icons.autorenew,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              MetricTile(
                label: 'Mingguan',
                value: MoneyFormatter.idr(state.weeklySubscriptionMinor),
                helper: 'Langganan',
                icon: Icons.view_week_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Segera jatuh tempo',
                value: state.dueSoonCount.toString(),
                helper: '7 hari ke depan',
                icon: Icons.event_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackerTabs extends StatelessWidget {
  const _TrackerTabs({required this.selected, required this.onChanged});

  final TrackerTab selected;
  final ValueChanged<TrackerTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TrackerTab>(
      segments: const [
        ButtonSegment(
          value: TrackerTab.installments,
          label: Text('Cicilan', key: Key('tracker-installments-tab')),
        ),
        ButtonSegment(
          value: TrackerTab.subscriptions,
          label: Text('Langganan', key: Key('tracker-subscriptions-tab')),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _InstallmentList extends StatelessWidget {
  const _InstallmentList({required this.state, required this.controller});

  final TrackerState state;
  final TrackerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Cicilan',
          actionLabel: state.installmentTotal == 0
              ? null
              : '${state.installmentTotal} total',
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        if (state.installments.isEmpty)
          const _TrackerEmptyState(
            title: 'Belum ada cicilan',
            body:
                'Pantau tenor, jumlah jatuh tempo bulanan, dan sisa pembayaran.',
            icon: Icons.receipt_long_outlined,
          )
        else
          for (final item in state.installments) ...[
            _InstallmentCard(
              item: item,
              walletName: state.walletName(item.walletId),
              categoryName: state.categoryName(item.categoryId),
              onPay: item.canPay
                  ? () => _showTrackerPaymentSheet(
                      context,
                      title: 'Bayar cicilan',
                      subtitle:
                          '${item.name} · ${MoneyFormatter.idr(item.monthlyAmountMinor)}',
                      onSave: (request) =>
                          controller.payInstallment(item, request),
                    )
                  : null,
              onEdit: () => _showTrackerForm(context, state, installment: item),
              onCancel: item.status == InstallmentStatus.cancelled
                  ? null
                  : () => _confirm(
                      context,
                      title: 'Batalkan cicilan?',
                      body:
                          'Ini menyimpan catatan dan menandai cicilan sebagai dibatalkan.',
                      actionLabel: 'Batalkan cicilan',
                      onConfirm: () => controller.cancelInstallment(item),
                    ),
              onDelete: () => _confirm(
                context,
                title: 'Hapus cicilan?',
                body:
                    'Ini menghapus cicilan dan jadwalnya secara permanen. Tindakan ini tidak dapat dibatalkan.',
                actionLabel: 'Hapus cicilan',
                onConfirm: () => controller.deleteInstallment(item),
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
      ],
    );
  }
}

class _SubscriptionList extends StatelessWidget {
  const _SubscriptionList({required this.state, required this.controller});

  final TrackerState state;
  final TrackerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Langganan',
          actionLabel: state.subscriptionTotal == 0
              ? null
              : '${state.subscriptionTotal} total',
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        if (state.subscriptions.isEmpty)
          const _TrackerEmptyState(
            title: 'Belum ada langganan',
            body:
                'Pantau pembayaran langganan aplikasi, layanan, dan langganan berulang.',
            icon: Icons.autorenew,
          )
        else
          for (final item in state.subscriptions) ...[
            _SubscriptionCard(
              item: item,
              walletName: state.walletName(item.walletId),
              categoryName: state.categoryName(item.categoryId),
              onPay: item.canPay
                  ? () => _showTrackerPaymentSheet(
                      context,
                      title: 'Bayar langganan',
                      subtitle:
                          '${item.name} · ${MoneyFormatter.idr(item.amountMinor)}',
                      onSave: (request) =>
                          controller.paySubscription(item, request),
                    )
                  : null,
              onEdit: () =>
                  _showTrackerForm(context, state, subscription: item),
              onPause: item.status == SubscriptionStatus.active
                  ? () => controller.setSubscriptionStatus(
                      item,
                      SubscriptionStatus.paused,
                    )
                  : null,
              onResume: item.status == SubscriptionStatus.paused
                  ? () => controller.setSubscriptionStatus(
                      item,
                      SubscriptionStatus.active,
                    )
                  : null,
              onCancel: item.status == SubscriptionStatus.cancelled
                  ? null
                  : () => _confirm(
                      context,
                      title: 'Batalkan langganan?',
                      body:
                          'Ini menyimpan catatan dan menandai langganan sebagai dibatalkan.',
                      actionLabel: 'Batalkan langganan',
                      onConfirm: () => controller.setSubscriptionStatus(
                        item,
                        SubscriptionStatus.cancelled,
                      ),
                    ),
              onDelete: () => _confirm(
                context,
                title: 'Hapus langganan?',
                body:
                    'Ini menghapus langganan secara permanen. Tindakan ini tidak dapat dibatalkan.',
                actionLabel: 'Hapus langganan',
                onConfirm: () => controller.deleteSubscription(item),
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
      ],
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    required this.item,
    required this.walletName,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    this.onPay,
    this.onCancel,
  });

  final Installment item;
  final String walletName;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return _TrackerCard(
      title: item.name,
      // The installment's own icon wins over the generic receipt glyph.
      icon: resolveEntityIcon(item.icon, Icons.receipt_long_outlined),
      colorHex: item.color,
      statusApiValue: item.status.apiValue,
      statusLabel: item.status.label,
      amount: MoneyFormatter.idr(item.monthlyAmountMinor),
      progress: item.paidPercent / 100,
      meta:
          'Sisa ${item.remainingMonths}/${item.tenorMonths} bulan · jatuh tempo tanggal ${item.dueDay}',
      detail: '$walletName · $categoryName',
      note: item.note,
      actionLabel: 'Bayar cicilan',
      onAction: onPay,
      menuItems: [
        _TrackerMenuItem(label: 'Ubah', onTap: onEdit),
        if (onCancel != null)
          _TrackerMenuItem(
            label: 'Batalkan cicilan',
            onTap: onCancel!,
            destructive: true,
          ),
        _TrackerMenuItem(
          label: 'Hapus cicilan',
          onTap: onDelete,
          destructive: true,
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.item,
    required this.walletName,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    this.onPay,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  final Subscription item;
  final String walletName;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPay;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return _TrackerCard(
      title: item.name,
      // The subscription's own icon wins over the generic renew glyph.
      icon: resolveEntityIcon(item.icon, Icons.autorenew),
      colorHex: item.color,
      statusApiValue: item.status.apiValue,
      statusLabel: item.status.label,
      amount: MoneyFormatter.idr(item.amountMinor),
      progress: item.status == SubscriptionStatus.active ? 1 : 0,
      meta:
          '${item.billingCycle.label} · jatuh tempo ${AffluenaDateFormatter.shortDate(item.nextDueDate)}',
      detail: '$walletName · $categoryName',
      note: item.accountDetail.isNotEmpty ? item.accountDetail : item.note,
      actionLabel: 'Bayar langganan',
      onAction: onPay,
      menuItems: [
        _TrackerMenuItem(label: 'Ubah', onTap: onEdit),
        if (onPause != null) _TrackerMenuItem(label: 'Jeda', onTap: onPause!),
        if (onResume != null)
          _TrackerMenuItem(label: 'Lanjutkan', onTap: onResume!),
        if (onCancel != null)
          _TrackerMenuItem(
            label: 'Batalkan langganan',
            onTap: onCancel!,
            destructive: true,
          ),
        _TrackerMenuItem(
          label: 'Hapus langganan',
          onTap: onDelete,
          destructive: true,
        ),
      ],
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({
    required this.title,
    required this.icon,
    required this.colorHex,
    required this.statusApiValue,
    required this.statusLabel,
    required this.amount,
    required this.progress,
    required this.meta,
    required this.detail,
    required this.menuItems,
    this.note = '',
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData icon;

  /// The item's chosen colour (may be empty) accenting the icon tile.
  final String colorHex;
  final String statusApiValue;
  final String statusLabel;
  final String amount;
  final double progress;
  final String meta;
  final String detail;
  final String note;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<_TrackerMenuItem> menuItems;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final normalizedStatus = statusApiValue.trim().toLowerCase();
    final progressColor = switch (normalizedStatus) {
      'paused' => colors.amber,
      'cancelled' || 'canceled' => colors.inkMuted,
      _ => colors.success,
    };
    // A valid user-chosen item color paints the whole row SOLID (the same
    // treatment as Beranda's dashboard cards): white text, white icon on a
    // translucent tile, white progress on a translucent track, onColor status
    // pill. Without one, the color only accents the icon tile as before.
    final custom = parseItemColor(colorHex);
    final hasColor = custom != null;

    return AffluenaCard(
      backgroundColor: hasColor ? custom : null,
      borderColor: hasColor ? custom : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasColor)
                ItemOnColorIconTile(icon: icon)
              else
                ItemAccentIconTile(
                  icon: icon,
                  colorHex: colorHex,
                  fallback: colors.forest,
                  fallbackBackground: colors.forestSoft,
                ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: Text(
                  title,
                  style: hasColor
                      ? textTheme.titleMedium?.copyWith(color: Colors.white)
                      : textTheme.titleMedium,
                ),
              ),
              StatusBadge.forStatus(
                statusApiValue,
                label: statusLabel,
                onColor: hasColor,
              ),
              PopupMenuButton<int>(
                iconColor: hasColor ? Colors.white : null,
                onSelected: (index) => menuItems[index].onTap(),
                itemBuilder: (context) => [
                  for (var i = 0; i < menuItems.length; i++)
                    PopupMenuItem(
                      value: i,
                      child: Text(
                        menuItems[i].label,
                        style: menuItems[i].destructive
                            ? TextStyle(color: colors.coral)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          SkyProgressBar(
            value: progress,
            height: 10,
            fillColor: hasColor ? Colors.white : progressColor,
            trackColor: hasColor
                ? Colors.white.withValues(alpha: 0.25)
                : colors.surfaceTintSoft,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            amount,
            style: hasColor
                ? textTheme.headlineSmall?.copyWith(color: Colors.white)
                : textTheme.headlineSmall,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            meta,
            style: hasColor
                ? textTheme.bodySmall?.copyWith(color: Colors.white70)
                : textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            detail,
            style: hasColor
                ? textTheme.bodySmall?.copyWith(color: Colors.white70)
                : textTheme.bodySmall,
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space2),
            Text(
              note,
              style: hasColor
                  ? textTheme.bodySmall?.copyWith(color: Colors.white70)
                  : textTheme.bodySmall,
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.payments_outlined),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackerMenuItem {
  const _TrackerMenuItem({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

class _TrackerEmptyState extends StatelessWidget {
  const _TrackerEmptyState({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

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
          Icon(icon, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(body, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TrackerLoading extends StatelessWidget {
  const _TrackerLoading();

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Cicilan & Langganan',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          const AffluenaCard(
            child: Column(
              children: [
                AffluenaSkeleton(height: 56),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton(height: 56),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaSkeleton(height: 48, radius: AffluenaRadii.control),
          const SizedBox(height: AffluenaSpacing.space5),
          for (var i = 0; i < 3; i++) ...[
            AffluenaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AffluenaSkeleton.line(width: 180, height: 16),
                  SizedBox(height: AffluenaSpacing.space3),
                  AffluenaSkeleton(height: 10, radius: AffluenaRadii.pill),
                  SizedBox(height: AffluenaSpacing.space3),
                  AffluenaSkeleton.line(width: 140, height: 20),
                  SizedBox(height: AffluenaSpacing.space2),
                  AffluenaSkeleton.line(width: 240),
                ],
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
        ],
      ),
    );
  }
}

class _TrackerError extends StatelessWidget {
  const _TrackerError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Cicilan & Langganan',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          AffluenaBanner.error(
            'Kami tidak dapat memuat cicilan & langganan kamu.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

Future<void> _showTrackerForm(
  BuildContext context,
  TrackerState state, {
  Installment? installment,
  Subscription? subscription,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TrackerFormSheet(
      state: state,
      installment: installment,
      subscription: subscription,
    ),
  );
}

class _TrackerFormSheet extends ConsumerStatefulWidget {
  const _TrackerFormSheet({
    required this.state,
    this.installment,
    this.subscription,
  });

  final TrackerState state;
  final Installment? installment;
  final Subscription? subscription;

  @override
  ConsumerState<_TrackerFormSheet> createState() => _TrackerFormSheetState();
}

class _TrackerFormSheetState extends ConsumerState<_TrackerFormSheet> {
  late TrackerTab _tab;
  late final TextEditingController _nameController;
  late final TextEditingController _tenorController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _accountController;
  late final TextEditingController _noteController;
  int? _amountMinor;
  int? _monthlyMinor;
  DateTime? _date;
  Wallet? _wallet;
  Category? _category;
  InstallmentStatus? _installmentStatus;
  SubscriptionStatus? _subscriptionStatus;
  BillingCycle _billingCycle = BillingCycle.monthly;
  // Chosen appearance. Null = no color (default section theming). When
  // editing, seeded from the item so an unrelated edit preserves it.
  String? _color;

  bool get _isEditing =>
      widget.installment != null || widget.subscription != null;

  @override
  void initState() {
    super.initState();
    final installment = widget.installment;
    final subscription = widget.subscription;
    _tab = installment != null
        ? TrackerTab.installments
        : subscription != null
        ? TrackerTab.subscriptions
        : widget.state.tab;
    _nameController = TextEditingController(
      text: installment?.name ?? subscription?.name ?? '',
    );
    _amountMinor = installment?.totalAmountMinor ?? subscription?.amountMinor;
    _monthlyMinor = installment?.monthlyAmountMinor;
    _tenorController = TextEditingController(
      text: installment?.tenorMonths.toString() ?? '',
    );
    _date = _parseDate(installment?.startDate ?? subscription?.nextDueDate);
    _dueDayController = TextEditingController(
      text: installment?.dueDay.toString() ?? '',
    );
    _accountController = TextEditingController(
      text: subscription?.accountDetail ?? '',
    );
    _noteController = TextEditingController(
      text: installment?.note ?? subscription?.note ?? '',
    );
    _installmentStatus = installment?.status;
    _subscriptionStatus = subscription?.status;
    _billingCycle = subscription?.billingCycle ?? BillingCycle.monthly;
    final storedColor = installment?.color ?? subscription?.color ?? '';
    _color = storedColor.isEmpty ? null : storedColor;
    _wallet = _findById(
      widget.state.wallets,
      installment?.walletId ?? subscription?.walletId,
    );
    _category = _findById(
      widget.state.categories,
      installment?.categoryId ?? subscription?.categoryId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tenorController.dispose();
    _dueDayController.dispose();
    _accountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Inline range feedback while typing; empty text stays quiet because the
  /// save button already gates on completeness.
  String? get _tenorError {
    final text = _tenorController.text.trim();
    if (text.isEmpty) return null;
    return _intValue(text) >= 1 ? null : 'Tenor minimal 1 bulan.';
  }

  String? get _dueDayError {
    final text = _dueDayController.text.trim();
    if (text.isEmpty) return null;
    final day = _intValue(text);
    return (day >= 1 && day <= 31) ? null : 'Isi tanggal antara 1-31.';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackerControllerProvider);
    final title = _isEditing
        ? 'Ubah catatan'
        : _tab == TrackerTab.installments
        ? 'Buat cicilan'
        : 'Buat langganan';
    final canSave =
        _nameController.text.trim().isNotEmpty &&
        _wallet != null &&
        _category != null &&
        (_amountMinor ?? 0) > 0 &&
        _date != null &&
        (_tab == TrackerTab.subscriptions ||
            ((_monthlyMinor ?? 0) > 0 &&
                _intValue(_tenorController.text) > 0 &&
                _intValue(_dueDayController.text) >= 1 &&
                _intValue(_dueDayController.text) <= 31)) &&
        !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              if (state.actionError != null) ...[
                AffluenaBanner.error(state.actionError!),
                const SizedBox(height: AffluenaSpacing.space4),
              ],
              if (!_isEditing)
                SegmentedButton<TrackerTab>(
                  segments: const [
                    ButtonSegment(
                      value: TrackerTab.installments,
                      label: Text('Cicilan'),
                    ),
                    ButtonSegment(
                      value: TrackerTab.subscriptions,
                      label: Text('Langganan'),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (values) =>
                      setState(() => _tab = values.first),
                ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.label_outline),
                  labelText: 'Nama',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_tab == TrackerTab.subscriptions) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                TextField(
                  controller: _accountController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                    labelText: 'Detail akun',
                  ),
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space2),
              SelectorRow(
                label: 'Dompet',
                value: _wallet?.name ?? 'Pilih dompet',
                isPlaceholder: _wallet == null,
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => _selectWallet(widget.state.wallets),
              ),
              const Divider(height: 1),
              SelectorRow(
                label: 'Kategori pengeluaran',
                value: _category?.name ?? 'Pilih kategori',
                isPlaceholder: _category == null,
                icon: Icons.category_outlined,
                onTap: () => _selectCategory(widget.state.categories),
              ),
              const Divider(height: 1),
              const SizedBox(height: AffluenaSpacing.space2),
              MoneyInput(
                key: const Key('tracker-amount-field'),
                label: _tab == TrackerTab.installments
                    ? 'Total jumlah'
                    : 'Jumlah',
                initialValue: _amountMinor,
                onChanged: (value) => setState(() => _amountMinor = value),
              ),
              if (_tab == TrackerTab.installments) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                MoneyInput(
                  label: 'Jumlah bulanan',
                  initialValue: _monthlyMinor,
                  onChanged: (value) => setState(() => _monthlyMinor = value),
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                TextField(
                  controller: _tenorController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.timelapse_outlined),
                    labelText: 'Tenor (bulan)',
                    errorText: _tenorError,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                TextField(
                  controller: _dueDayController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.event_outlined),
                    labelText: 'Tanggal jatuh tempo',
                    hintText: '1-31',
                    helperText:
                        'Di bulan yang lebih pendek dipakai tanggal terakhir '
                        'bulan itu (mis. 31 menjadi 28 Feb).',
                    helperMaxLines: 2,
                    errorText: _dueDayError,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                const SizedBox(height: AffluenaSpacing.space2),
                DropdownButtonFormField<BillingCycle>(
                  initialValue: _billingCycle,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.repeat),
                    labelText: 'Siklus penagihan',
                  ),
                  items: BillingCycle.values
                      .map(
                        (cycle) => DropdownMenuItem(
                          value: cycle,
                          child: Text(cycle.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (cycle) {
                    if (cycle == null) return;
                    setState(() => _billingCycle = cycle);
                  },
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                key: const Key('tracker-date-field'),
                // "Tagihan berikutnya": the subscription date is the NEXT
                // billing date, not when the subscription started.
                label: _tab == TrackerTab.installments
                    ? 'Tanggal mulai'
                    : 'Tagihan berikutnya',
                value: _date,
                icon: Icons.today_outlined,
                placeholder: 'Pilih tanggal',
                onChanged: (value) => setState(() => _date = value),
              ),
              if (_isEditing && _tab == TrackerTab.installments) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                DropdownButtonFormField<InstallmentStatus>(
                  initialValue: _installmentStatus,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_outlined),
                    labelText: 'Status',
                  ),
                  items: InstallmentStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (status) =>
                      setState(() => _installmentStatus = status),
                ),
              ],
              if (_isEditing && _tab == TrackerTab.subscriptions) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                DropdownButtonFormField<SubscriptionStatus>(
                  initialValue: _subscriptionStatus,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_outlined),
                    labelText: 'Status',
                  ),
                  items: SubscriptionStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (status) =>
                      setState(() => _subscriptionStatus = status),
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space4),
              Text(
                'Warna',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.affluenaColors.inkMuted,
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              ItemColorPickerRow(
                entity: _tab == TrackerTab.installments
                    ? 'installment'
                    : 'subscription',
                selected: _color,
                enabled: !state.isSaving,
                onChanged: (hex) => setState(() => _color = hex),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  labelText: 'Catatan',
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('tracker-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectWallet(List<Wallet> wallets) async {
    final selected = await showLookupSelectorSheet<Wallet>(
      context: context,
      title: 'Dompet',
      searchHint: 'Cari dompet',
      selectedValue: _wallet,
      options: [
        for (final wallet in wallets)
          LookupSelectorOption<Wallet>(
            value: wallet,
            label: wallet.name,
            subtitle: wallet.type.apiValue,
            icon: Icons.account_balance_wallet_outlined,
          ),
      ],
    );
    if (selected == null) return;
    setState(() => _wallet = selected);
  }

  Future<void> _selectCategory(List<Category> categories) async {
    // Categories are a hierarchy: use the tree-aware picker, not a flat list.
    final selectedId = await showCategoryTreePicker(
      context: context,
      title: 'Kategori pengeluaran',
      selectedId: _category?.id,
      quickAdd: const CategoryQuickAdd(type: CategoryType.expense),
      onMutated: () => ref.read(trackerControllerProvider.notifier).load(),
      categories: [
        for (final category in categories)
          CategoryTreeEntry.fromCategory(category),
      ],
    );
    if (!mounted || selectedId == null || selectedId.isEmpty) return;
    // Resolve against the live controller state: a category created inline
    // from the picker only exists there, not in the snapshot the sheet holds.
    final selected = [
      ...categories,
      ...ref.read(trackerControllerProvider).categories,
    ].where((candidate) => candidate.id == selectedId).firstOrNull;
    if (selected == null) return;
    setState(() => _category = selected);
  }

  Future<void> _save() async {
    final controller = ref.read(trackerControllerProvider.notifier);
    final note = _noteController.text.trim();
    final dateValue = _formatDate(_date)!;

    if (_tab == TrackerTab.installments) {
      final request = InstallmentRequest(
        name: _nameController.text.trim(),
        walletId: _wallet!.id,
        categoryId: _category!.id,
        totalAmountMinor: _amountMinor ?? 0,
        monthlyAmountMinor: _monthlyMinor ?? 0,
        tenorMonths: _intValue(_tenorController.text),
        remainingMonths: widget.installment?.remainingMonths,
        startDate: dateValue,
        dueDay: _intValue(_dueDayController.text),
        status: _installmentStatus,
        note: note,
        // Always send the color ('' = cleared) so picking "no color" on edit
        // actually removes it; the icon is threaded through unchanged.
        color: _color ?? '',
        icon: widget.installment?.icon,
      );
      if (widget.installment == null) {
        await controller.createInstallment(request);
      } else {
        await controller.updateInstallment(widget.installment!, request);
      }
    } else {
      final request = SubscriptionRequest(
        name: _nameController.text.trim(),
        accountDetail: _accountController.text.trim(),
        walletId: _wallet!.id,
        categoryId: _category!.id,
        amountMinor: _amountMinor ?? 0,
        billingCycle: _billingCycle,
        nextDueDate: dateValue,
        status: _subscriptionStatus,
        note: note,
        // Always send the color ('' = cleared) so picking "no color" on edit
        // actually removes it; the icon is threaded through unchanged.
        color: _color ?? '',
        icon: widget.subscription?.icon,
      );
      if (widget.subscription == null) {
        await controller.createSubscription(request);
      } else {
        await controller.updateSubscription(widget.subscription!, request);
      }
    }
    if (!mounted) return;
    if (ref.read(trackerControllerProvider).actionError == null) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> _showTrackerPaymentSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Future<void> Function(TrackerPaymentRequest request) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _TrackerPaymentSheet(title: title, subtitle: subtitle, onSave: onSave),
  );
}

class _TrackerPaymentSheet extends ConsumerStatefulWidget {
  const _TrackerPaymentSheet({
    required this.title,
    required this.subtitle,
    required this.onSave,
  });

  final String title;
  final String subtitle;
  final Future<void> Function(TrackerPaymentRequest request) onSave;

  @override
  ConsumerState<_TrackerPaymentSheet> createState() =>
      _TrackerPaymentSheetState();
}

class _TrackerPaymentSheetState extends ConsumerState<_TrackerPaymentSheet> {
  final _noteController = TextEditingController();
  DateTime? _paidAt;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackerControllerProvider);
    final canSave = !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space2),
              Text(widget.subtitle),
              const SizedBox(height: AffluenaSpacing.space4),
              if (state.actionError != null) ...[
                AffluenaBanner.error(state.actionError!),
                const SizedBox(height: AffluenaSpacing.space4),
              ],
              DatePickerField(
                key: const Key('tracker-payment-date-field'),
                label: 'Dibayar pada',
                value: _paidAt,
                icon: Icons.today_outlined,
                placeholder: 'Opsional · default hari ini',
                onChanged: (value) => setState(() => _paidAt = value),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  labelText: 'Catatan',
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('tracker-payment-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(
                  state.isSaving ? 'Menyimpan...' : 'Simpan pembayaran',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.onSave(
      TrackerPaymentRequest(
        paidAt: _formatDateTime(_paidAt),
        note: _noteController.text.trim(),
      ),
    );
    if (!mounted) return;
    if (ref.read(trackerControllerProvider).actionError == null) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String actionLabel,
  required Future<void> Function() onConfirm,
}) async {
  final confirmed = await skyConfirm(
    context,
    title: title,
    message: body,
    confirmLabel: actionLabel,
    cancelLabel: 'Pertahankan',
  );
  if (confirmed) {
    await onConfirm();
  }
}

T? _findById<T>(List<T> items, String? id) {
  if (id == null) return null;
  for (final item in items) {
    final value = switch (item) {
      Wallet(:final id) => id,
      Category(:final id) => id,
      _ => null,
    };
    if (value == id) return item;
  }
  return null;
}

int _intValue(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(normalized) ?? 0;
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

String? _formatDate(DateTime? value) {
  if (value == null) return null;
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String? _formatDateTime(DateTime? value) {
  if (value == null) return null;
  return value.toUtc().toIso8601String();
}
