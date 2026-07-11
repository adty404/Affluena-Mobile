import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/auth_validators.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import 'settings_sheet_widgets.dart';

/// Password-confirmed permanent account deletion (the in-app half of the
/// Google Play account-deletion requirement; the public web instructions live
/// at /hapus-akun). On success the auth controller clears the local session +
/// armed reminders and the router lands on the login screen — this sheet only
/// needs to close itself.
Future<void> showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  String? _errorMessage;
  bool _isDeleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coral = context.affluenaColors.coral;
    return SettingsSheetFrame(
      title: 'Hapus akun',
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AffluenaBanner.error(
              'Akun dan SEMUA datamu — dompet, transaksi, anggaran, target, '
              'utang, langganan — dihapus permanen seketika dan tidak bisa '
              'dibatalkan. Ekspor dulu datamu bila masih diperlukan.',
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            TextFormField(
              key: const Key('settings-delete-account-password-field'),
              controller: _passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              validator: (value) => AuthValidators.required(
                value,
                message: 'Masukkan kata sandimu untuk konfirmasi.',
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              onFieldSubmitted: (_) => _delete(),
              decoration: const InputDecoration(
                labelText: 'Konfirmasi kata sandi',
                hintText: 'Kata sandimu saat ini',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AffluenaSpacing.space3),
              AffluenaBanner.error(_errorMessage!),
            ],
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton.icon(
              key: const Key('settings-delete-account-button'),
              // No foregroundColor: the theme supplies onPrimary (white in
              // light, near-black in dark) — hardcoding Colors.white washes
              // out on dark-mode's lighter coral (same pattern as skyConfirm's
              // danger button).
              style: FilledButton.styleFrom(backgroundColor: coral),
              onPressed: _isDeleting ? null : _delete,
              icon: _isDeleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: Text(_isDeleting ? 'Menghapus...' : 'Hapus akun permanen'),
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            TextButton(
              key: const Key('settings-delete-account-cancel'),
              onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    if (_isDeleting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() {
      _errorMessage = null;
      _isDeleting = true;
    });
    final error = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(_passwordController.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isDeleting = false;
      });
      return;
    }
    // Success: the auth state is already unauthenticated (router redirects to
    // login); just close the sheet.
    Navigator.of(context).pop();
  }
}
