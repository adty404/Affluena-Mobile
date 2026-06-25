import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../application/device_auth_service.dart';
import '../application/settings_controller.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _unlockedForSession = false;
  bool _isAuthenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldLockOnResume()) {
      setState(() {
        _locked = true;
        _unlockedForSession = false;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final securityPreferences = ref.watch(securityPreferencesProvider);
    final securityState = securityPreferences.asData?.value;
    final shouldProtect =
        authState.isAuthenticated &&
        securityState?.preferences.deviceLockEnabled == true &&
        securityState?.isDeviceAuthSupported == true;
    final wasJustEnabled =
        securityState?.actionMessage == 'Device lock enabled.';

    _syncLockState(shouldProtect: shouldProtect, skipLock: wasJustEnabled);

    if (_locked && shouldProtect) {
      return _AppLockScreen(
        isAuthenticating: _isAuthenticating,
        error: _error,
        onUnlock: _unlock,
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      );
    }

    return widget.child;
  }

  bool _shouldLockOnResume() {
    final authState = ref.read(authControllerProvider);
    final securityState = ref.read(securityPreferencesProvider).asData?.value;
    return authState.isAuthenticated &&
        securityState?.preferences.deviceLockEnabled == true &&
        securityState?.isDeviceAuthSupported == true;
  }

  void _syncLockState({required bool shouldProtect, required bool skipLock}) {
    if (!shouldProtect) {
      if (_locked || _unlockedForSession || _error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _locked = false;
            _unlockedForSession = false;
            _error = null;
          });
        });
      }
      return;
    }

    if (!_locked && !_unlockedForSession && !skipLock) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _locked = true);
      });
    }
  }

  Future<void> _unlock() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final unlocked = await ref.read(deviceAuthServiceProvider).authenticate();
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _locked = !unlocked;
        _unlockedForSession = unlocked;
        _error = unlocked
            ? null
            : 'Could not verify it was you. Tap Unlock to try again, or use '
                  'your device passcode. Make sure a fingerprint/face or screen '
                  'lock is set up in device settings.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _error =
            'Device authentication is unavailable. Set up a fingerprint, '
            'face, or screen lock in your device settings, or log out.';
      });
    }
  }
}

class _AppLockScreen extends StatefulWidget {
  const _AppLockScreen({
    required this.isAuthenticating,
    required this.onUnlock,
    required this.onLogout,
    this.error,
  });

  final bool isAuthenticating;
  final String? error;
  final VoidCallback onUnlock;
  final VoidCallback onLogout;

  @override
  State<_AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<_AppLockScreen> {
  @override
  void initState() {
    super.initState();
    // Fire biometric automatically the moment the lock screen appears so the
    // user sees the system prompt without first tapping a button.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.isAuthenticating && widget.error == null) {
        widget.onUnlock();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticating = widget.isAuthenticating;
    final error = widget.error;
    final onUnlock = widget.onUnlock;
    final onLogout = widget.onLogout;
    final colors = context.affluenaColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AffluenaSpacing.space5),
          child: Center(
            child: AffluenaCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.forestSoft,
                        borderRadius: BorderRadius.circular(AffluenaRadii.md),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AffluenaSpacing.space3),
                        child: Icon(
                          Icons.fingerprint,
                          color: colors.forest,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AffluenaSpacing.space5),
                  Text('Affluena locked', style: textTheme.headlineMedium),
                  const SizedBox(height: AffluenaSpacing.space2),
                  Text(
                    'Use your device authentication to continue your signed-in finance session.',
                    style: textTheme.bodyMedium,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AffluenaSpacing.space4),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.coral.withAlpha(32),
                        borderRadius: BorderRadius.circular(AffluenaRadii.lg),
                        border: Border.all(color: colors.coral),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AffluenaSpacing.space3),
                        child: Text(
                          error,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AffluenaSpacing.space5),
                  FilledButton.icon(
                    key: const Key('app-lock-unlock-button'),
                    onPressed: isAuthenticating ? null : onUnlock,
                    icon: isAuthenticating
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.surfaceCanvas,
                            ),
                          )
                        : const Icon(Icons.lock_open_outlined),
                    label: Text(
                      isAuthenticating ? 'Authenticating' : 'Unlock Affluena',
                    ),
                  ),
                  const SizedBox(height: AffluenaSpacing.space2),
                  TextButton(
                    key: const Key('app-lock-logout-button'),
                    onPressed: isAuthenticating ? null : onLogout,
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
