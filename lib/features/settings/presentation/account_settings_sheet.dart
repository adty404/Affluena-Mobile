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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('settings-name-field'),
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nama',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          TextField(
            key: const Key('settings-avatar-field'),
            controller: _avatarController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'URL avatar',
              prefixIcon: Icon(Icons.image_outlined),
            ),
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
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama wajib diisi.');
      return;
    }
    setState(() {
      _error = null;
      _isSaving = true;
    });
    final result = await ref
        .read(settingsProfileProvider.notifier)
        .updateAccount(
          UpdateAccountRequest(
            name: name,
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
