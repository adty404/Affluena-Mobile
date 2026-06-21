import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../application/auth_controller.dart';

class AuthBootstrapScreen extends StatelessWidget {
  const AuthBootstrapScreen({super.key});

  static const path = '/auth/bootstrap';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandMark(size: 64),
              const SizedBox(height: AffluenaSpacing.space4),
              Text('Affluena', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space2),
              Text('Preparing your workspace', style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const path = '/auth/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return _AuthShell(
      title: 'Welcome back',
      subtitle: 'Log in to keep your balances, wallets, and entries in sync.',
      message: authState.message,
      children: [
        TextField(
          key: const Key('login-email-field'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextField(
          key: const Key('login-password-field'),
          controller: _passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(authState),
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SubmitButton(
          key: const Key('login-submit-button'),
          isSubmitting: authState.isSubmitting,
          icon: Icons.login,
          label: 'Log in',
          onPressed: () => _submit(authState),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: authState.isSubmitting
                    ? null
                    : () => context.go(RegisterScreen.path),
                child: const Text('Create account'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: authState.isSubmitting
                    ? null
                    : () => context.go(ForgotPasswordScreen.path),
                child: const Text('Forgot password'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _submit(AuthState authState) {
    if (authState.isSubmitting) return;
    ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const path = '/auth/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return _AuthShell(
      title: 'Create account',
      subtitle: 'Start with a secure account, then connect your Affluena data.',
      message: authState.message,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextField(
          controller: _passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _submit(authState),
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SubmitButton(
          isSubmitting: authState.isSubmitting,
          icon: Icons.person_add_alt_1_outlined,
          label: 'Register',
          onPressed: () => _submit(authState),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextButton(
          onPressed: authState.isSubmitting
              ? null
              : () => context.go(LoginScreen.path),
          child: const Text('I already have an account'),
        ),
      ],
    );
  }

  void _submit(AuthState authState) {
    if (authState.isSubmitting) return;
    ref
        .read(authControllerProvider.notifier)
        .register(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const path = '/auth/forgot-password';

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return _AuthShell(
      title: 'Reset access',
      subtitle: 'Send a reset link to your Affluena account email.',
      message: authState.message,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _submit(authState),
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SubmitButton(
          isSubmitting: authState.isSubmitting,
          icon: Icons.mark_email_read_outlined,
          label: 'Send reset link',
          onPressed: () => _submit(authState),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextButton(
          onPressed: authState.isSubmitting
              ? null
              : () => context.go(LoginScreen.path),
          child: const Text('Back to login'),
        ),
      ],
    );
  }

  void _submit(AuthState authState) {
    if (authState.isSubmitting) return;
    ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(_emailController.text);
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  static const path = '/auth/reset-password';

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return _AuthShell(
      title: 'New password',
      subtitle: 'Paste the reset token and choose a fresh password.',
      message: authState.message,
      children: [
        TextField(
          controller: _tokenController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Reset token',
            prefixIcon: Icon(Icons.key_outlined),
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextField(
          controller: _passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _submit(authState),
          decoration: const InputDecoration(
            labelText: 'New password',
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SubmitButton(
          isSubmitting: authState.isSubmitting,
          icon: Icons.done_outline,
          label: 'Update password',
          onPressed: () => _submit(authState),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextButton(
          onPressed: authState.isSubmitting
              ? null
              : () => context.go(LoginScreen.path),
          child: const Text('Back to login'),
        ),
      ],
    );
  }

  void _submit(AuthState authState) {
    if (authState.isSubmitting) return;
    ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          token: _tokenController.text,
          newPassword: _passwordController.text,
        );
  }
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({
    required this.title,
    required this.subtitle,
    required this.children,
    this.message,
  });

  final String title;
  final String subtitle;
  final String? message;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AffluenaSpacing.space5,
                AffluenaSpacing.space5,
                AffluenaSpacing.space5,
                AffluenaSpacing.space8,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: AffluenaSpacing.space8),
                    Text(title, style: textTheme.displaySmall),
                    const SizedBox(height: AffluenaSpacing.space3),
                    Text(subtitle, style: textTheme.bodyMedium),
                    if (message != null && message!.isNotEmpty) ...[
                      const SizedBox(height: AffluenaSpacing.space4),
                      _AuthMessage(message: message!),
                    ],
                    const SizedBox(height: AffluenaSpacing.space5),
                    ...children,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const _BrandMark(size: 44),
        const SizedBox(width: AffluenaSpacing.space3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Affluena', style: textTheme.titleMedium),
            Text('Finance companion', style: textTheme.labelMedium),
          ],
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AffluenaColors.forest,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        color: AffluenaColors.surfaceElevated,
        size: size * 0.5,
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AffluenaSpacing.space3),
      decoration: BoxDecoration(
        color: AffluenaColors.forestSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AffluenaColors.borderSubtle),
      ),
      child: Text(message, style: textTheme.bodySmall),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSubmitting,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final bool isSubmitting;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isSubmitting ? null : onPressed,
      icon: isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(isSubmitting ? 'Please wait' : label),
    );
  }
}
