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
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.sky.accent,
        foregroundColor: Colors.white,
        onPressed: () => showSkyQuickAddSheet(context),
        child: const Icon(Icons.add),
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
        color: context.sky.surface,
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
            icon: Icons.home_outlined,
            label: 'Beranda',
            active: currentIndex == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Aktivitas',
            active: currentIndex == 1,
            onTap: () => onSelect(1),
          ),
          _NavItem(
            icon: Icons.insights_outlined,
            label: 'Wawasan',
            active: currentIndex == 2,
            onTap: () => onSelect(2),
          ),
          _NavItem(
            icon: Icons.more_horiz,
            label: 'Lainnya',
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
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
          horizontal: AffluenaSpacing.space2,
          vertical: AffluenaSpacing.space1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
