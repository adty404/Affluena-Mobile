import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/data/auth_models.dart';
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
  String? _message;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetFrame(
      title: 'Password',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('settings-current-password-field'),
            controller: _currentController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Current password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          TextField(
            key: const Key('settings-new-password-field'),
            controller: _newController,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'New password',
              prefixIcon: Icon(Icons.lock_reset_outlined),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            SettingsInlineMessage(message: _message!, isError: true),
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
            label: Text(_isSaving ? 'Updating' : 'Update password'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_newController.text.length < 8) {
      setState(() => _message = 'Password must be at least 8 characters.');
      return;
    }
    setState(() {
      _message = null;
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
    setState(() {
      _isSaving = false;
      _message = result.message;
    });
  }
}
