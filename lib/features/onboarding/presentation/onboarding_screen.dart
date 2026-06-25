import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../application/onboarding_controller.dart';

class _Slide {
  const _Slide({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

const _slides = <_Slide>[
  _Slide(
    icon: Icons.bolt_outlined,
    title: 'Track money in seconds',
    body:
        'Log income and expenses fast, manage cash, bank, and e-wallet '
        'accounts, and reuse one-tap quick entries.',
  ),
  _Slide(
    icon: Icons.insights_outlined,
    title: 'Plan budgets, reach goals',
    body:
        'Set monthly category limits, follow installments and subscriptions, '
        'and grow your savings toward every goal.',
  ),
  _Slide(
    icon: Icons.verified_user_outlined,
    title: 'Private and always in sync',
    body:
        'A biometric app lock, a full activity trail, and your data synced '
        'across every device.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({this.replay = false, super.key});

  static const path = '/onboarding';
  static String replayLocation() => '/onboarding?replay=true';

  /// When true the screen is being reviewed from settings rather than shown on
  /// first run, so finishing simply returns instead of completing onboarding.
  final bool replay;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slides.length - 1;

  void _finish() {
    if (widget.replay) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
      return;
    }
    ref.read(onboardingControllerProvider.notifier).complete();
    // The router redirect routes on to login/dashboard once completed.
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip (hidden on the last slide where the primary CTA takes over).
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: AffluenaSpacing.space3,
                    ),
                    child: TextButton(
                      onPressed: _isLast ? null : _finish,
                      child: const Text('Skip'),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _Dots(count: _slides.length, index: _index),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AffluenaSpacing.space5,
                AffluenaSpacing.space5,
                AffluenaSpacing.space5,
                AffluenaSpacing.space6,
              ),
              child: FilledButton(
                key: const Key('onboarding-primary-button'),
                onPressed: _next,
                child: Text(_isLast ? 'Get started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AffluenaSpacing.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.forestSoft,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AffluenaSpacing.space8),
              child: Icon(slide.icon, color: colors.forest, size: 56),
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space8),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: colors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(
              horizontal: AffluenaSpacing.space1,
            ),
            height: 8,
            width: i == index ? 22 : 8,
            decoration: BoxDecoration(
              color: i == index ? colors.forest : colors.borderSubtle,
              borderRadius: BorderRadius.circular(AffluenaRadii.pill),
            ),
          ),
      ],
    );
  }
}
