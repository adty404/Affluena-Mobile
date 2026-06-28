import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../settings/presentation/settings_screen.dart';
import 'activity_feed_screen.dart';
import 'beranda_dashboard_screen.dart';
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
    BerandaDashboardView(),
    ActivityFeedView(),
    SkyInsightsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sky.ground,
      // Let the body run under the floating nav so the pill truly hovers over
      // the content (the lists add bottom padding to clear it).
      extendBody: true,
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

/// A floating pill navigation bar: it hovers above the content with rounded
/// ends, a soft shadow, and the ground colour showing around it (rather than a
/// full-width bar attached to the screen edge).
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          AffluenaSpacing.space3,
        ),
        // A Row (not Center/Align) so the bar sizes to the pill's height — a
        // height-expanding widget here would eat the whole screen and collapse
        // the body.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: context.sky.surface,
                borderRadius: BorderRadius.circular(AffluenaRadii.pill),
                border: Border.all(color: context.sky.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x291E2A38), // #1E2A38 @ 16%
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
            ),
          ],
        ),
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
    final iconColor = active ? context.sky.accent : context.sky.faint;
    return InkResponse(
      onTap: onTap,
      radius: 32,
      containedInkWell: true,
      customBorder: const CircleBorder(),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? context.sky.accentSoft : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 26, color: iconColor),
      ),
    );
  }
}
