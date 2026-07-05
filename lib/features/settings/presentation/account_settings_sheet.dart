import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/data/auth_models.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../application/settings_controller.dart';
import 'settings_sheet_widgets.dart';

Future<String?> showAccountSettingsSheet(BuildContext context, AuthUser user) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AccountSheet(user: user),
  );
}

class _AccountSheet extends ConsumerStatefulWidget {
  const _AccountSheet({required this.user});

  final AuthUser user;

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _avatarController;
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _avatarController = TextEditingController(text: widget.user.avatarUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSheetFrame(
      title: 'Akun',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('settings-name-field'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'Budi Santoso',
                prefixIcon: Icon(Icons.person_outline),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Nama wajib diisi.' : null,
              onChanged: (_) => _clearError(),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            TextFormField(
              key: const Key('settings-avatar-field'),
              controller: _avatarController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'URL avatar',
                hintText: 'https://contoh.com/foto.jpg',
                prefixIcon: Icon(Icons.image_outlined),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validateAvatarUrl,
              onChanged: (_) => _clearError(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AffluenaSpacing.space3),
              AffluenaBanner.error(_error!),
            ],
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton.icon(
              key: const Key('settings-account-save-button'),
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_outline),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan akun'),
            ),
          ],
        ),
      ),
    );
  }

  /// Clears a lingering save-error banner once the user starts correcting the
  /// input (same pattern as the wallet invite sheet).
  void _clearError() {
    if (_error == null) return;
    setState(() => _error = null);
  }

  /// Empty is fine (no avatar); anything else must be an absolute http(s) URL
  /// or it would silently render broken images later.
  String? _validateAvatarUrl(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    final isValid =
        uri != null &&
        uri.isAbsolute &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return isValid ? null : 'Masukkan URL yang valid.';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _error = null;
      _isSaving = true;
    });
    final result = await ref
        .read(settingsProfileProvider.notifier)
        .updateAccount(
          UpdateAccountRequest(
            name: _nameController.text.trim(),
            avatarUrl: _avatarController.text.trim(),
          ),
        );
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(result.message);
      return;
    }
    setState(() {
      _isSaving = false;
      _error = result.message;
    });
  }
}
