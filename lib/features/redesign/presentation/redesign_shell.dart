import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../settings/presentation/settings_screen.dart';
import 'activity_feed_screen.dart';
import 'rooms_home_screen.dart';
import 'sky_insights_screen.dart';
import 'sky_quick_add_sheet.dart';

/// Redesign Tahap 7 (integration) — the unified nav shell that ties the
/// redesign screens together: Home (rooms) · Aktivitas · Insights as tabs, a
/// center quick-add FAB, and "Lainnya" to reach Settings (and the remaining
/// feature screens). Mounted additively at /beranda; promoting it to the
/// authenticated default + retiring the old dashboard/5-tab shell + the
/// app-wide palette migration is the final integration sub-stage.
class RedesignShell extends StatefulWidget {
  const RedesignShell({super.key});

  static const path = '/beranda';

  @override
  State<RedesignShell> createState() => _RedesignShellState();
}

class _RedesignShellState extends State<RedesignShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    RoomsHomeView(),
    ActivityFeedView(),
    SkyInsightsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sky.ground,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _tabs),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.sky.accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: context.sky.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          onPressed: () => showSkyQuickAddSheet(context),
          child: const Icon(Icons.add),
        ),
      ),
      bottomNavigationBar: _SkyBottomNav(
        currentIndex: _index,
        onSelect: (index) => setState(() => _index = index),
        onMore: () => context.push(SettingsScreen.path),
      ),
    );
  }
}

class _SkyBottomNav extends StatelessWidget {
  const _SkyBottomNav({
    required this.currentIndex,
    required this.onSelect,
    required this.onMore,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.sky.sheet,
        border: Border(top: BorderSide(color: context.sky.line)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AffluenaSpacing.space2,
        AffluenaSpacing.space2,
        AffluenaSpacing.space2,
        AffluenaSpacing.space3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            key: const ValueKey('nav-beranda'),
            icon: Icons.home_outlined,
            active: currentIndex == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            key: const ValueKey('nav-aktivitas'),
            icon: Icons.receipt_long_outlined,
            active: currentIndex == 1,
            onTap: () => onSelect(1),
          ),
          _NavItem(
            key: const ValueKey('nav-wawasan'),
            icon: Icons.insights_outlined,
            active: currentIndex == 2,
            onTap: () => onSelect(2),
          ),
          _NavItem(
            key: const ValueKey('nav-lainnya'),
            icon: Icons.more_horiz,
            active: false,
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? context.sky.accent : context.sky.faint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AffluenaRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space3,
          vertical: AffluenaSpacing.space2,
        ),
        child: Icon(icon, size: 24, color: color),
      ),
    );
  }
}
