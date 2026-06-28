import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_validators.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../application/settings_controller.dart';
import 'settings_sheet_widgets.dart';

Future<String?> showPasswordSettingsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _PasswordSheet(),
  );
}

class _PasswordSheet extends ConsumerStatefulWidget {
  const _PasswordSheet();

  @override
  ConsumerState<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends ConsumerState<_PasswordSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetFrame(
      title: 'Kata sandi',
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('settings-current-password-field'),
              controller: _currentController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.next,
              validator: (value) => AuthValidators.required(
                value,
                message: 'Masukkan kata sandimu saat ini.',
              ),
              decoration: const InputDecoration(
                labelText: 'Kata sandi saat ini',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            TextFormField(
              key: const Key('settings-new-password-field'),
              controller: _newController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              validator: AuthValidators.password,
              decoration: const InputDecoration(
                labelText: 'Kata sandi baru',
                helperText: 'Minimal 8 karakter.',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            TextFormField(
              key: const Key('settings-confirm-password-field'),
              controller: _confirmController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  AuthValidators.confirmPassword(_newController.text, value),
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Konfirmasi kata sandi baru',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AffluenaSpacing.space3),
              AffluenaBanner.error(_errorMessage!),
            ],
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton.icon(
              key: const Key('settings-password-save-button'),
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset_outlined),
              label: Text(_isSaving ? 'Memperbarui...' : 'Perbarui kata sandi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });
    final result = await ref
        .read(settingsProfileProvider.notifier)
        .changePassword(
          ChangePasswordRequest(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          ),
        );
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(result.message);
      return;
    }
    // Keep the sheet open on failure and surface the error inline.
    setState(() {
      _isSaving = false;
      _errorMessage = result.message;
    });
  }
}
