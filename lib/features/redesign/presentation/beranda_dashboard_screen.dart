import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/section_palette.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../budgets/application/budget_controller.dart';
import '../../budgets/data/budget_models.dart';
import '../../budgets/presentation/budget_detail_screen.dart';
import '../../budgets/presentation/budget_screen.dart';
import '../../categories/data/category_models.dart';
import '../../goals/application/goal_controller.dart';
import '../../goals/data/goal_models.dart';
import '../../goals/presentation/goal_detail_screen.dart';
import '../../goals/presentation/goal_screen.dart';
import '../../partner/application/partner_controller.dart';
import '../../partner/presentation/shared_with_me_screen.dart';
import '../../recurring/application/recurring_controller.dart';
import '../../recurring/data/recurring_models.dart';
import '../../recurring/presentation/recurring_detail_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';
import '../../shared/presentation/widgets/empty_state.dart';
import '../../shared/presentation/widgets/error_state.dart';
import '../../shared/presentation/widgets/sky_avatar.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../../trackers/application/tracker_controller.dart';
import '../../trackers/data/tracker_models.dart';
import '../../trackers/presentation/installment_detail_screen.dart';
import '../../trackers/presentation/subscription_detail_screen.dart';
import '../../trackers/presentation/tracker_screen.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/presentation/wallet_appearance.dart';
import '../../wallets/presentation/wallet_format.dart';
import '../../wallets/presentation/wallets_screen.dart';
import 'room_detail_screen.dart';
import 'sky_quick_add_sheet.dart';

/// Redesign — Beranda as a **sectioned dashboard** (Sky & Denim). A `Total saldo`
/// hero over six money-domain sections (Dompet · Anggaran · Tabungan · Cicilan ·
/// Langganan · Berulang); each section is a header with a "Lihat semua" link over
/// a 2-column card grid, and tapping a card opens that domain. Replaces the
/// earlier wallet-"rooms" home as the first nav tab.
///
/// See `design/affluena-design-guide.html` (the visual source of truth) and
/// `DESIGN.md` §1.
class BerandaDashboardView extends ConsumerWidget {
  const BerandaDashboardView({super.key});

  /// How many cards each section shows inline; the rest live behind "Lihat semua".
  static const _previewCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final budgetState = ref.watch(budgetControllerProvider);
    final goalState = ref.watch(goalControllerProvider);
    final trackerState = ref.watch(trackerControllerProvider);
    final recurringState = ref.watch(recurringControllerProvider);

    final partnerState = ref.watch(partnerControllerProvider);
    final viewableOwnerIds = partnerState.viewableOwnerIds;
    final sharerName = <String, String>{
      for (final link in partnerState.links)
        if (link.isIncoming && link.isJoined) link.userId: link.displayName,
    };
    bool isPartnerWallet(Wallet w) =>
        w.role == 'viewer' && viewableOwnerIds.contains(w.userId);

    final wallets = walletsAsync.asData?.value ?? const <Wallet>[];
    final partnerWallets = wallets
        .where(isPartnerWallet)
        .toList(growable: false);
    final spending = wallets
        .where((w) => !w.isGoal && !isPartnerWallet(w))
        .toList(growable: false);
    final total = spending.fold<int>(0, (sum, w) => sum + w.balanceMinor);

    final savings = goalState.goals
        .where((g) => g.isActive)
        .toList(growable: false);
    final installments = trackerState.installments;
    final subscriptions = trackerState.subscriptions;
    final recurring = recurringState.rules;

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        // Always scrollable so pull-to-refresh works even on a short page.
        physics: const AlwaysScrollableScrollPhysics(),
        // Extra bottom padding so the last row clears the floating nav pill.
        padding: AffluenaInsets.screen.copyWith(bottom: 120),
        children: [
          _Hero(
            total: total,
            loading: walletsAsync.isLoading && spending.isEmpty,
          ),
          const SizedBox(height: AffluenaSpacing.space6),

          _Section(
            title: 'Dompet',
            onSeeAll: () => context.push(WalletsScreen.path),
            isLoading: walletsAsync.isLoading && spending.isEmpty,
            hasError: walletsAsync.hasError && spending.isEmpty,
            onRetry: () => ref.invalidate(walletListProvider),
            emptyLabel: 'Belum ada dompet',
            onEmptyTap: () => context.push(WalletsScreen.path),
            cards: [
              for (final wallet in spending.take(_previewCount))
                _walletCard(context, wallet),
            ],
          ),

          if (partnerWallets.isNotEmpty)
            _Section(
              title: 'Dibagikan untukku',
              onSeeAll: () => context.push(SharedWithMeScreen.path),
              isLoading: false,
              hasError: false,
              onRetry: () {},
              emptyLabel: '',
              onEmptyTap: () {},
              cards: [
                for (final wallet in partnerWallets.take(_previewCount))
                  _partnerWalletCard(
                    context,
                    wallet,
                    sharerName[wallet.userId],
                  ),
              ],
            ),

          _Section(
            title: 'Anggaran',
            onSeeAll: () => context.push(BudgetScreen.path),
            isLoading: budgetState.isLoading && budgetState.budgets.isEmpty,
            hasError:
                budgetState.loadError != null && budgetState.budgets.isEmpty,
            onRetry: () => ref.invalidate(budgetControllerProvider),
            emptyLabel: 'Belum ada anggaran',
            onEmptyTap: () => context.push(BudgetScreen.path),
            cards: [
              for (final budget in budgetState.budgets.take(_previewCount))
                _budgetCard(
                  context,
                  name: budgetState.categoryName(budget.categoryId),
                  budget: budget,
                  category: budgetState.categories
                      .where((category) => category.id == budget.categoryId)
                      .firstOrNull,
                ),
            ],
          ),

          _Section(
            title: 'Tabungan',
            onSeeAll: () => context.push(GoalScreen.path),
            isLoading: goalState.isLoading && savings.isEmpty,
            hasError: goalState.loadError != null && savings.isEmpty,
            onRetry: () => ref.invalidate(goalControllerProvider),
            emptyLabel: 'Belum ada tabungan',
            onEmptyTap: () => context.push(GoalScreen.path),
            cards: [
              for (final goal in savings.take(_previewCount))
                _goalCard(context, goal),
            ],
          ),

          _Section(
            title: 'Cicilan',
            onSeeAll: () => context.push(TrackerScreen.path),
            isLoading: trackerState.isLoading && installments.isEmpty,
            hasError: trackerState.loadError != null && installments.isEmpty,
            onRetry: () => ref.invalidate(trackerControllerProvider),
            emptyLabel: 'Belum ada cicilan',
            onEmptyTap: () => context.push(TrackerScreen.path),
            cards: [
              for (final item in installments.take(_previewCount))
                _installmentCard(context, item),
            ],
          ),

          _Section(
            title: 'Langganan',
            onSeeAll: () => context.push(TrackerScreen.path),
            isLoading: trackerState.isLoading && subscriptions.isEmpty,
            hasError: trackerState.loadError != null && subscriptions.isEmpty,
            onRetry: () => ref.invalidate(trackerControllerProvider),
            emptyLabel: 'Belum ada langganan',
            onEmptyTap: () => context.push(TrackerScreen.path),
            cards: [
              for (final item in subscriptions.take(_previewCount))
                _subscriptionCard(context, item),
            ],
          ),

          _Section(
            title: 'Berulang',
            onSeeAll: () => context.push(RecurringScreen.path),
            isLoading: recurringState.isLoading && recurring.isEmpty,
            hasError: recurringState.loadError != null && recurring.isEmpty,
            onRetry: () => ref.invalidate(recurringControllerProvider),
            emptyLabel: 'Belum ada transaksi berulang',
            onEmptyTap: () => context.push(RecurringScreen.path),
            isLast: true,
            cards: [
              for (final rule in recurring.take(_previewCount))
                _recurringCard(context, rule),
            ],
          ),
        ],
      ),
    );
  }

  /// Pull-to-refresh: reload every dashboard section in parallel. Each
  /// controller stores its own load error, so a failed section falls back to
  /// its inline retry tile instead of failing the whole refresh.
  Future<void> _refresh(WidgetRef ref) async {
    final wallets = () async {
      ref.invalidate(walletListProvider);
      try {
        await ref.read(walletListProvider.future);
      } catch (_) {
        // The Dompet section renders its own error + retry.
      }
    }();
    await Future.wait([
      wallets,
      ref.read(budgetControllerProvider.notifier).load(),
      ref.read(goalControllerProvider.notifier).load(),
      ref.read(trackerControllerProvider.notifier).load(),
      ref.read(recurringControllerProvider.notifier).load(),
      ref.read(partnerControllerProvider.notifier).load(),
    ]);
  }

  // --- card builders -------------------------------------------------------

  Widget _walletCard(BuildContext context, Wallet wallet) {
    final shared =
        wallet.members.isNotEmpty ||
        (wallet.role != null && wallet.role != 'owner');
    final useAvatars = shared && wallet.members.length >= 2;

    final colorHex = wallet.color;
    final color = parseWalletColor(colorHex);
    final hasColor = color != null;
    final hue = SectionPalette.dompet.of(context);

    return _DashCard(
      // A user-chosen wallet colour wins; otherwise the section tint applies.
      backgroundColor: hasColor ? color : hue.tint,
      borderColor: hasColor ? color : hue.border,
      titleColor: hasColor ? Colors.white : null,
      subtitleColor: hasColor ? Colors.white70 : null,
      valueColor: hasColor ? Colors.white : null,
      leading: useAvatars
          ? _AvatarStack(
              members: wallet.members,
              ring: hasColor ? color : hue.tint,
            )
          : _IconTile(
              icon: resolveWalletIcon(wallet),
              customColor: hasColor ? Colors.white : hue.strong,
              customBg: hasColor
                  ? Colors.white.withValues(alpha: 0.2)
                  : hue.iconBg,
              customBorder: Colors.transparent,
            ),
      badge: wallet.isViewer
          ? const _Badge(label: 'LIHAT')
          : (shared ? const _Badge(label: 'BERSAMA') : null),
      title: wallet.name,
      subtitle: walletTypeLabel(wallet.type),
      value: MoneyFormatter.idr(wallet.balanceMinor),
      onTap: () => context.push(RoomDetailScreen.location(wallet.id)),
      onLongPress: () => showSkyQuickAddSheet(context, wallet: wallet),
    );
  }

  /// A wallet shared TO me — read-only (no long-press quick-add), shown in the
  /// "Dibagikan untukku" section. The subtitle names who shared it.
  Widget _partnerWalletCard(
    BuildContext context,
    Wallet wallet,
    String? ownerName,
  ) {
    final colorHex = wallet.color;
    final color = parseWalletColor(colorHex);
    final hasColor = color != null;
    final hue = SectionPalette.dibagikan.of(context);

    return _DashCard(
      backgroundColor: hasColor ? color : hue.tint,
      borderColor: hasColor ? color : hue.border,
      titleColor: hasColor ? Colors.white : null,
      subtitleColor: hasColor ? Colors.white70 : null,
      valueColor: hasColor ? Colors.white : null,
      leading: _IconTile(
        icon: resolveWalletIcon(wallet),
        customColor: hasColor ? Colors.white : hue.strong,
        customBg: hasColor ? Colors.white.withValues(alpha: 0.2) : hue.iconBg,
        customBorder: Colors.transparent,
      ),
      badge: const _Badge(label: 'LIHAT'),
      title: wallet.name,
      subtitle: ownerName != null
          ? 'dari $ownerName'
          : walletTypeLabel(wallet.type),
      value: MoneyFormatter.idr(wallet.balanceMinor),
      onTap: () => context.push(RoomDetailScreen.location(wallet.id)),
    );
  }

  Widget _budgetCard(
    BuildContext context, {
    required String name,
    required BudgetSummary budget,
    Category? category,
  }) {
    final over = budget.usagePercent >= 100;
    final hue = SectionPalette.anggaran.of(context);
    // A user-chosen item colour wins over the section tint — solid card,
    // white text/icon, exactly like a coloured wallet card. Over-budget
    // danger still wins on the progress fill.
    final color = parseItemColor(budget.color);
    final hasColor = color != null;
    return _DashCard(
      backgroundColor: hasColor ? color : hue.tint,
      borderColor: hasColor ? color : hue.border,
      titleColor: hasColor ? Colors.white : null,
      subtitleColor: hasColor ? Colors.white70 : null,
      leading: _IconTile(
        // The budget's own icon wins over its category's icon, which wins
        // over the generic pie glyph — same precedence as the budget rows.
        icon: resolveEntityIcon(
          budget.icon,
          (category != null ? categoryIconFor(category.icon) : null) ??
              Icons.pie_chart_outline,
        ),
        customColor: hasColor ? Colors.white : hue.strong,
        customBg: hasColor ? Colors.white.withValues(alpha: 0.2) : hue.iconBg,
        customBorder: Colors.transparent,
      ),
      title: name,
      subtitle:
          '${MoneyFormatter.idr(budget.spentMinor)} / ${MoneyFormatter.idr(budget.limitMinor)}',
      progress: budget.usagePercent / 100,
      progressColor: over
          ? context.sky.danger
          : (hasColor ? Colors.white : hue.strong),
      progressTrackColor: hasColor
          ? Colors.white.withValues(alpha: 0.25)
          : null,
      value: '${budget.usagePercent.round()}%',
      valueColor: hasColor
          ? Colors.white
          : (over ? context.sky.danger : hue.strong),
      onTap: () => context.push(BudgetDetailScreen.location(budget.id)),
    );
  }

  Widget _goalCard(BuildContext context, Goal goal) {
    final hue = SectionPalette.tabungan.of(context);
    final color = parseItemColor(goal.color);
    final hasColor = color != null;
    return _DashCard(
      backgroundColor: hasColor ? color : hue.tint,
      borderColor: hasColor ? color : hue.border,
      titleColor: hasColor ? Colors.white : null,
      subtitleColor: hasColor ? Colors.white70 : null,
      leading: _IconTile(
        icon: resolveEntityIcon(goal.icon, Icons.savings_outlined),
        customColor: hasColor ? Colors.white : hue.strong,
        customBg: hasColor ? Colors.white.withValues(alpha: 0.2) : hue.iconBg,
        customBorder: Colors.transparent,
      ),
      title: goal.name,
      subtitle:
          '${MoneyFormatter.idr(goal.collectedAmountMinor)} / ${MoneyFormatter.idr(goal.targetAmountMinor)}',
      progress: goal.progressPercent / 100,
      progressColor: hasColor ? Colors.white : hue.strong,
      progressTrackColor: hasColor
          ? Colors.white.withValues(alpha: 0.25)
          : null,
      value: '${goal.progressPercent}%',
      valueColor: hasColor ? Colors.white : hue.strong,
      onTap: () => context.push(GoalDetailScreen.location(goal.id)),
    );
  }

  Widget _installmentCard(BuildContext context, Installment item) {
    final paid = item.tenorMonths - item.remainingMonths;
    final hue = SectionPalette.cicilan.of(context);
    final color = parseItemColor(item.color);
    final hasColor = color != null;
    return _DashCard(
      backgroundColor: hasColor ? color : hue.tint,
      borderColor: hasColor ? color : hue.border,
      titleColor: hasColor ? Colors.white : null,
      subtitleColor: hasColor ? Colors.white70 : null,
      leading: _IconTile(
        icon: resolveEntityIcon(item.icon, Icons.credit_card_outlined),
        customColor: hasColor ? Colors.white : hue.strong,
        customBg: hasColor ? Colors.white.withValues(alpha: 0.2) : hue.iconBg,
        customBorder: Colors.transparent,
      ),
      title: item.name,
      subtitle: '$paid/${item.tenorMonths} terbayar',
      progress: item.paidPercent / 100,
      progressColor: hasColor ? Colors.white : hue.strong,
      progressTrackColor: hasColor
          ? Colors.white.withValues(alpha: 0.25)
          : null,
      value: '${MoneyFormatter.idr(item.monthlyAmountMinor)}/bln',
      onTap: () => context.push(InstallmentDetailScreen.location(item.id)),
    );
  }

  Widget _subscriptionCard(BuildContext context, Subscription item) {
    final hue = SectionPalette.langganan.of(context);
    final color = parseItemColor(item.color);
    final hasColor = color != null;
    return _DashCard(
      backgroundColor: hasColor ? color : hue.tint,
      borderColor: hasColor ? color : hue.border,
      titleColor: hasColor ? Colors.white : null,
      subtitleColor: hasColor ? Colors.white70 : null,
      leading: _IconTile(
        icon: resolveEntityIcon(item.icon, Icons.subscriptions_outlined),
        customColor: hasColor ? Colors.white : hue.strong,
        customBg: hasColor ? Colors.white.withValues(alpha: 0.2) : hue.iconBg,
        customBorder: Colors.transparent,
      ),
      title: item.name,
      subtitle: item.billingCycle.label,
      value: MoneyFormatter.idr(item.amountMinor),
      onTap: () => context.push(SubscriptionDetailScreen.location(item.id)),
    );
  }

  Widget _recurringCard(BuildContext context, RecurringRule rule) {
    final income = rule.type == RecurringType.income;
    final hue = SectionPalette.berulang.of(context);
    final color = parseItemColor(rule.color);
    final hasColor = color != null;
    return _DashCard(
      backgroundColor: hasColor ? color : hue.tint,
      borderColor: hasColor ? color : hue.border,
      titleColor: hasColor ? Colors.white : null,
      subtitleColor: hasColor ? Colors.white70 : null,
      leading: _IconTile(
        icon: resolveEntityIcon(rule.icon, _recurringIcon(rule.type)),
        customColor: hasColor ? Colors.white : hue.strong,
        customBg: hasColor ? Colors.white.withValues(alpha: 0.2) : hue.iconBg,
        customBorder: Colors.transparent,
      ),
      title: rule.name,
      subtitle: rule.type.label,
      value: MoneyFormatter.idr(rule.amountMinor),
      valueColor: hasColor
          ? Colors.white
          : (income ? context.sky.income : context.sky.ink),
      onTap: () => context.push(RecurringDetailScreen.location(rule.id)),
    );
  }
}

IconData _recurringIcon(RecurringType type) {
  return switch (type) {
    RecurringType.income => Icons.south_west,
    RecurringType.expense => Icons.north_east,
    RecurringType.transfer => Icons.swap_horiz,
    RecurringType.adjustment => Icons.tune,
  };
}

// --- hero --------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.total, required this.loading});

  final int total;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total saldo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.sky.muted,
          ),
        ),
        const SizedBox(height: 3),
        if (loading)
          _Skeleton(width: 180, height: 30)
        else
          Text(
            MoneyFormatter.idr(total),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: context.sky.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        const SizedBox(height: 5),
        Text(
          'Saldo gabungan semua dompet',
          style: TextStyle(fontSize: 11.5, color: context.sky.faint),
        ),
      ],
    );
  }
}

// --- section -----------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.onSeeAll,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    required this.emptyLabel,
    required this.onEmptyTap,
    required this.cards,
    this.isLast = false,
  });

  final String title;
  final VoidCallback onSeeAll;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;
  final String emptyLabel;
  final VoidCallback onEmptyTap;
  final List<Widget> cards;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (hasError) {
      content = ErrorState.compact(onRetry: onRetry);
    } else if (isLoading) {
      content = _CardGrid(children: const [_SkeletonCard(), _SkeletonCard()]);
    } else if (cards.isEmpty) {
      // Keeps the existing behaviour: tapping the tile opens the domain
      // screen where the first item can be created.
      content = EmptyState.compact(title: emptyLabel, onTap: onEmptyTap);
    } else {
      content = _CardGrid(children: cards);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AffluenaSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: context.sky.ink,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onSeeAll,
                borderRadius: BorderRadius.circular(AffluenaRadii.md),
                // ≥44px hit target: the link stays visually a small text
                // label, but its tappable box is grown to a comfortable size.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AffluenaSpacing.space2,
                      ),
                      child: Text(
                        'Lihat semua',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.sky.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          content,
        ],
      ),
    );
  }
}

/// Lays children out in a 2-column grid, pairing rows so the two cards in each
/// row share a height.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final left = children[i];
      final right = i + 1 < children.length ? children[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) {
        rows.add(const SizedBox(height: AffluenaSpacing.space3));
      }
    }
    return Column(children: rows);
  }
}

// --- card --------------------------------------------------------------------

class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.valueColor,
    this.badge,
    this.progress,
    this.progressColor,
    this.progressTrackColor,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.titleColor,
    this.subtitleColor,
  });

  final Widget leading;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final String? value;
  final Color? valueColor;
  final Widget? badge;
  final double? progress;
  final Color? progressColor;

  /// Track behind the progress fill — a translucent white on solid coloured
  /// cards so the bar stays legible on the user's colour.
  final Color? progressTrackColor;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? context.sky.surface,
      borderRadius: BorderRadius.circular(AffluenaRadii.control),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AffluenaRadii.control),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor ?? context.sky.line),
            borderRadius: BorderRadius.circular(AffluenaRadii.control),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  leading,
                  if (badge != null) ...[const Spacer(), badge!],
                ],
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? context.sky.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: subtitleColor ?? context.sky.muted,
                  ),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                SkyProgressBar(
                  value: progress!,
                  height: 6,
                  fillColor: progressColor,
                  trackColor: progressTrackColor,
                ),
              ],
              if (value != null) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: valueColor ?? titleColor ?? context.sky.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- shared bits -------------------------------------------------------------

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    this.customColor,
    this.customBg,
    this.customBorder,
  });

  final IconData icon;
  final Color? customColor;
  final Color? customBg;
  final Color? customBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: customBg ?? context.sky.sheet,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: customBorder ?? context.sky.line),
      ),
      child: Icon(icon, size: 18, color: customColor ?? context.sky.muted),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members, this.ring});

  final List<WalletMember> members;

  /// Ring colour between overlapping avatars — match the card background so
  /// the overlap reads as a cutout.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    String initial(WalletMember m) =>
        m.email.isEmpty ? '?' : m.email[0].toUpperCase();
    final ringColor = ring ?? context.sky.accentSoft;

    return SizedBox(
      width: 44,
      height: 34,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 3,
            child: SkyAvatar(
              initial: initial(members[0]),
              borderColor: ringColor,
            ),
          ),
          Positioned(
            left: 15,
            top: 3,
            child: SkyAvatar(
              initial: initial(members[1]),
              color: context.sky.avatarSecondary,
              borderColor: ringColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.sky.accentSoft,
        borderRadius: BorderRadius.circular(AffluenaRadii.pill),
        border: Border.all(color: context.sky.accentSoftBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: context.sky.accentInk,
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: context.sky.sheet,
        border: Border.all(color: context.sky.line),
        borderRadius: BorderRadius.circular(AffluenaRadii.control),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.sky.sheet,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
