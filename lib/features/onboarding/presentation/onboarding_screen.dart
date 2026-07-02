import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../redesign/presentation/redesign_shell.dart';
import '../../shared/presentation/widgets/sky_avatar.dart';
import '../application/onboarding_controller.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    this.couple = false,
  });
  final IconData icon;
  final String title;
  final String body;

  /// The first slide shows the shared-wallet hero (floating balance + avatars).
  final bool couple;
}

const _slides = <_Slide>[
  _Slide(
    icon: Icons.account_balance_wallet_outlined,
    title: 'Atur uang berdua, tenang.',
    body:
        'Catat pengeluaran, bagi dompet, dan capai tujuan bareng pasangan '
        'tanpa ribet.',
    couple: true,
  ),
  _Slide(
    icon: Icons.savings_outlined,
    title: 'Anggaran & target bersama',
    body:
        'Pantau anggaran, cicilan, dan langganan, lalu kembangkan tabungan '
        'menuju tiap target.',
  ),
  _Slide(
    icon: Icons.lock_outline,
    title: 'Privat dan selalu sinkron',
    body:
        'Kunci aplikasi biometrik, jejak aktivitas lengkap, dan datamu '
        'tersinkron di setiap perangkat.',
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
        context.go(RedesignShell.path);
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
      backgroundColor: context.sky.ground,
      body: SafeArea(
        child: Column(
          children: [
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
                AffluenaSpacing.space2,
              ),
              child: FilledButton(
                key: const Key('onboarding-primary-button'),
                onPressed: _next,
                child: Text(_isLast ? 'Mulai' : 'Lanjut'),
              ),
            ),
            if (!widget.replay)
              Padding(
                padding: const EdgeInsets.only(bottom: AffluenaSpacing.space4),
                child: TextButton(
                  onPressed: _finish,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Sudah punya akun? ',
                          style: TextStyle(color: context.sky.muted),
                        ),
                        TextSpan(
                          text: 'Masuk',
                          style: TextStyle(
                            color: context.sky.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AffluenaSpacing.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _HeroArt(icon: slide.icon, couple: slide.couple),
          const SizedBox(height: AffluenaSpacing.space8),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: context.sky.ink,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: context.sky.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The Sky & Denim onboarding illustration: a soft ring holding a domain icon.
/// The first ("couple") slide overlays a floating shared-balance card and the
/// two partner avatars, matching the design guide.
class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.icon, required this.couple});

  final IconData icon;
  final bool couple;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [context.sky.accentSoft, context.sky.accentSoftBorder],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 56, color: context.sky.accent),
          ),
          if (couple) ...[
            Positioned(
              right: 28,
              top: 26,
              child: SizedBox(
                width: 44,
                height: 34,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 3,
                      child: SkyAvatar(
                        initial: 'A',
                        borderColor: context.sky.ground,
                      ),
                    ),
                    Positioned(
                      left: 15,
                      top: 3,
                      child: SkyAvatar(
                        initial: 'S',
                        color: context.sky.avatarSecondary,
                        borderColor: context.sky.ground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: context.sky.surface,
                  borderRadius: BorderRadius.circular(AffluenaRadii.md),
                  border: Border.all(color: context.sky.line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x23000000),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total bersama',
                      style: TextStyle(fontSize: 10, color: context.sky.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp 8.450.000',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: context.sky.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              color: i == index ? context.sky.accent : context.sky.line,
              borderRadius: BorderRadius.circular(AffluenaRadii.pill),
            ),
          ),
      ],
    );
  }
}
