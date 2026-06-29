import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
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
      title: 'Masuk',
      subtitle: 'Lanjutkan mengatur keuangan berdua.',
      message: authState.message,
      messageTone: authState.messageTone,
      children: [
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SkyField(
                fieldKey: const Key('login-email-field'),
                controller: _emailController,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              _SkyField(
                fieldKey: const Key('login-password-field'),
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (value) => AuthValidators.required(
                  value,
                  message: 'Masukkan kata sandimu.',
                ),
                onSubmitted: (_) => _submit(authState),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: authState.isSubmitting
                ? null
                : () => context.go(ForgotPasswordScreen.path),
            child: const Text('Lupa password?'),
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space2),
        _SubmitButton(
          key: const Key('login-submit-button'),
          isSubmitting: authState.isSubmitting,
          label: 'Masuk',
          onPressed: () => _submit(authState),
        ),
        const SizedBox(height: AffluenaSpacing.space2),
        _AuthLink(
          lead: 'Belum punya akun?',
          action: 'Daftar',
          onTap: authState.isSubmitting
              ? null
              : () => context.go(RegisterScreen.path),
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
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _agreed = false;

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
      title: 'Buat akun',
      subtitle: 'Mulai kelola uang bersama dalam sebentar.',
      message: authState.message,
      messageTone: authState.messageTone,
      children: [
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SkyField(
                fieldKey: const Key('register-email-field'),
                controller: _emailController,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              _SkyField(
                fieldKey: const Key('register-password-field'),
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.password,
                helperText: 'Minimal 8 karakter.',
                onSubmitted: (_) => _submit(authState),
              ),
            ],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        _TermsCheckbox(
          value: _agreed,
          onChanged: (value) => setState(() => _agreed = value),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SubmitButton(
          key: const Key('register-submit-button'),
          isSubmitting: authState.isSubmitting,
          label: 'Daftar',
          onPressed: _agreed ? () => _submit(authState) : null,
        ),
        const SizedBox(height: AffluenaSpacing.space2),
        _AuthLink(
          lead: 'Sudah punya akun?',
          action: 'Masuk',
          onTap: authState.isSubmitting
              ? null
              : () => context.go(LoginScreen.path),
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
    required this.label,
    required this.onPressed,
    super.key,
  });

  final bool isSubmitting;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: (isSubmitting || onPressed == null) ? null : onPressed,
      child: isSubmitting
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AffluenaSpacing.space2),
                Text('Mohon tunggu'),
              ],
            )
          : Text(label),
    );
  }
}

/// A Sky & Denim text field for the auth screens: an external label over a
/// rounded, filled input with a leading icon and (for passwords) an eye toggle.
class _SkyField extends StatefulWidget {
  const _SkyField({
    required this.controller,
    required this.label,
    required this.icon,
    this.fieldKey,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.obscure = false,
    this.helperText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Key? fieldKey;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final String? Function(String?)? validator;
  final bool obscure;
  final String? helperText;
  final void Function(String)? onSubmitted;

  @override
  State<_SkyField> createState() => _SkyFieldState();
}

class _SkyFieldState extends State<_SkyField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AffluenaRadii.control);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.sky.muted,
            ),
          ),
        ),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          validator: widget.validator,
          obscureText: _obscured,
          onFieldSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: context.sky.surface,
            helperText: widget.helperText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AffluenaSpacing.space4,
              vertical: 14,
            ),
            prefixIcon: Icon(widget.icon, size: 18, color: context.sky.faint),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: context.sky.faint,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
            border: border(context.sky.line),
            enabledBorder: border(context.sky.line),
            focusedBorder: border(context.sky.accent, 1.6),
            errorBorder: border(context.sky.danger),
            focusedErrorBorder: border(context.sky.danger, 1.6),
          ),
        ),
      ],
    );
  }
}

/// A centered "lead + action" footer link, e.g. "Belum punya akun? Daftar".
class _AuthLink extends StatelessWidget {
  const _AuthLink({required this.lead, required this.action, this.onTap});

  final String lead;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$lead ',
                style: TextStyle(color: context.sky.muted),
              ),
              TextSpan(
                text: action,
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
    );
  }
}

/// The "Saya setuju…" terms acceptance row on the register screen.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.md),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (next) => onChanged(next ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AffluenaSpacing.space3),
            Expanded(
              child: Text(
                'Saya setuju dengan Syarat & Kebijakan Privasi.',
                style: TextStyle(fontSize: 12.5, color: context.sky.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
