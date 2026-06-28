import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../application/auth_controller.dart';
import 'auth_validators.dart';

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
              Text('Menyiapkan ruang kerjamu', style: textTheme.bodySmall),
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
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

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
      title: 'Selamat datang kembali',
      subtitle: 'Masuk untuk menyinkronkan saldo, dompet, dan transaksimu.',
      message: authState.message,
      messageTone: authState.messageTone,
      children: [
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('login-email-field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextFormField(
                key: const Key('login-password-field'),
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) => AuthValidators.required(
                  value,
                  message: 'Masukkan kata sandimu.',
                ),
                onFieldSubmitted: (_) => _submit(authState),
                decoration: const InputDecoration(
                  labelText: 'Kata sandi',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SubmitButton(
          key: const Key('login-submit-button'),
          isSubmitting: authState.isSubmitting,
          icon: Icons.login,
          label: 'Masuk',
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
                child: const Text('Daftar'),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: authState.isSubmitting
                    ? null
                    : () => context.go(ForgotPasswordScreen.path),
                child: const Text('Lupa kata sandi'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _submit(AuthState authState) {
    if (authState.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
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
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return _AuthShell(
      title: 'Daftar',
      subtitle: 'Mulai dengan akun yang aman, lalu hubungkan data Affluena-mu.',
      message: authState.message,
      messageTone: authState.messageTone,
      children: [
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('register-email-field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextFormField(
                key: const Key('register-password-field'),
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.password,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi',
                  helperText: 'Minimal 8 karakter.',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextFormField(
                key: const Key('register-confirm-password-field'),
                controller: _confirmController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => AuthValidators.confirmPassword(
                  _passwordController.text,
                  value,
                ),
                onFieldSubmitted: (_) => _submit(authState),
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi kata sandi',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SubmitButton(
          key: const Key('register-submit-button'),
          isSubmitting: authState.isSubmitting,
          icon: Icons.person_add_alt_1_outlined,
          label: 'Daftar',
          onPressed: () => _submit(authState),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextButton(
          onPressed: authState.isSubmitting
              ? null
              : () => context.go(LoginScreen.path),
          child: const Text('Aku sudah punya akun'),
        ),
      ],
    );
  }

  void _submit(AuthState authState) {
    if (authState.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
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
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return _AuthShell(
      title: 'Atur ulang akses',
      subtitle:
          'Kami akan mengirim kode atur ulang ke akun Affluena-mu lewat email. '
          'Masukkan kode itu di layar berikutnya untuk memilih kata sandi baru.',
      message: authState.message,
      messageTone: authState.messageTone,
      children: [
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: TextFormField(
            key: const Key('forgot-email-field'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: AuthValidators.email,
            onFieldSubmitted: (_) => _submit(authState),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SubmitButton(
          key: const Key('forgot-submit-button'),
          isSubmitting: authState.isSubmitting,
          icon: Icons.mark_email_read_outlined,
          label: 'Kirimi aku kode',
          onPressed: () => _submit(authState),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextButton(
          onPressed: authState.isSubmitting
              ? null
              : () => context.go(LoginScreen.path),
          child: const Text('Kembali ke masuk'),
        ),
      ],
    );
  }

  Future<void> _submit(AuthState authState) async {
    if (authState.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    final email = _emailController.text.trim();
    final sent = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(email);
    if (!mounted || !sent) return;
    // Carry the email forward so the reset screen can keep context. Push keeps
    // forgot-password underneath so the user can step back to re-send a code.
    context.push(ResetPasswordScreen.path, extra: email);
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({this.email, this.token, super.key});

  static const path = '/auth/reset-password';

  /// Email carried over from the forgot-password step (shown for context).
  final String? email;

  /// Reset code prefilled from a deep link (e.g. /auth/reset-password?token=…).
  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _codeController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.token?.trim() ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final email = widget.email?.trim();

    return _AuthShell(
      title: 'Kata sandi baru',
      subtitle: email != null && email.isNotEmpty
          ? 'Masukkan kode yang kami kirim ke $email, lalu pilih kata sandi baru.'
          : 'Masukkan kode dari email-mu, lalu pilih kata sandi baru.',
      message: authState.message,
      messageTone: authState.messageTone,
      children: [
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('reset-code-field'),
                controller: _codeController,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                validator: AuthValidators.resetCode,
                decoration: InputDecoration(
                  labelText: 'Kode atur ulang',
                  helperText: 'Kode dari email-mu.',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  suffixIcon: IconButton(
                    key: const Key('reset-code-paste-button'),
                    tooltip: 'Tempel kode',
                    icon: const Icon(Icons.content_paste_outlined),
                    onPressed: _pasteCode,
                  ),
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextFormField(
                key: const Key('reset-password-field'),
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.password,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi baru',
                  helperText: 'Minimal 8 karakter.',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextFormField(
                key: const Key('reset-confirm-password-field'),
                controller: _confirmController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => AuthValidators.confirmPassword(
                  _passwordController.text,
                  value,
                ),
                onFieldSubmitted: (_) => _submit(authState),
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi kata sandi',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SubmitButton(
          key: const Key('reset-submit-button'),
          isSubmitting: authState.isSubmitting,
          icon: Icons.done_outline,
          label: 'Perbarui kata sandi',
          onPressed: () => _submit(authState),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextButton(
          key: const Key('reset-back-to-login-button'),
          onPressed: authState.isSubmitting
              ? null
              : () => context.go(LoginScreen.path),
          child: const Text('Kembali ke masuk'),
        ),
      ],
    );
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _codeController.text = text;
  }

  Future<void> _submit(AuthState authState) async {
    if (authState.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          token: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );
    if (!mounted || !success || _completed) return;
    // Land back on login so the user signs in with the new password. The
    // success banner persists in auth state and reads on the login screen.
    _completed = true;
    context.go(LoginScreen.path);
  }
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({
    required this.title,
    required this.subtitle,
    required this.children,
    this.message,
    this.messageTone = AuthMessageTone.info,
  });

  final String title;
  final String subtitle;
  final String? message;
  final AuthMessageTone messageTone;
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
                      _AuthMessage(message: message!, tone: messageTone),
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
            Text('Teman keuanganmu', style: textTheme.labelMedium),
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
    final colors = context.affluenaColors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.forest,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        color: colors.surfaceCanvas,
        size: size * 0.5,
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message, required this.tone});

  final String message;
  final AuthMessageTone tone;

  @override
  Widget build(BuildContext context) {
    switch (tone) {
      case AuthMessageTone.error:
        return AffluenaBanner.error(message);
      case AuthMessageTone.success:
        return AffluenaBanner.success(message);
      case AuthMessageTone.info:
        return AffluenaBanner(message: message, tone: AffluenaBannerTone.info);
    }
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
      label: Text(isSubmitting ? 'Mohon tunggu' : label),
    );
  }
}
