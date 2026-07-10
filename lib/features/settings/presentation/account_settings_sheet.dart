import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/data/auth_models.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/avatar_image.dart';
import '../application/avatar_picker.dart';
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
  final _formKey = GlobalKey<FormState>();

  /// The avatar value that will be saved: the untouched existing URL, a fresh
  /// `data:image/...` payload from "Pilih foto", or '' after "Hapus foto".
  late String _avatarUrl;
  String? _error;
  bool _isSaving = false;
  bool _isProcessingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _avatarUrl = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            _buildAvatarRow(context),
            const SizedBox(height: AffluenaSpacing.space4),
            TextFormField(
              key: const Key('settings-name-field'),
              controller: _nameController,
              textInputAction: TextInputAction.done,
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

  /// The avatar picker row: current photo (or the name/email initial) beside
  /// "Pilih foto" (system photo picker) and "Hapus foto". Replaces the old
  /// hand-typed "URL avatar" field; legacy http(s) avatars keep rendering and
  /// are preserved untouched unless the user picks or removes a photo.
  Widget _buildAvatarRow(BuildContext context) {
    final colors = context.affluenaColors;
    final textTheme = Theme.of(context).textTheme;
    final image = avatarImageProvider(_avatarUrl);
    final initialSource = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : widget.user.email;
    final initial = initialSource.isEmpty
        ? 'A'
        : initialSource.characters.first.toUpperCase();

    return Row(
      children: [
        ExcludeSemantics(
          child: CircleAvatar(
            key: const Key('settings-avatar-preview'),
            radius: 28,
            backgroundColor: colors.forest,
            foregroundImage: image,
            child: Text(
              initial,
              style: textTheme.titleLarge?.copyWith(
                color: colors.surfaceCanvas,
              ),
            ),
          ),
        ),
        const SizedBox(width: AffluenaSpacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Foto profil',
                style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              Wrap(
                spacing: AffluenaSpacing.space2,
                runSpacing: AffluenaSpacing.space2,
                children: [
                  OutlinedButton.icon(
                    key: const Key('settings-avatar-pick-button'),
                    onPressed: _isSaving || _isProcessingPhoto
                        ? null
                        : _pickPhoto,
                    icon: _isProcessingPhoto
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(
                      _isProcessingPhoto ? 'Memproses...' : 'Pilih foto',
                    ),
                  ),
                  if (_avatarUrl.isNotEmpty)
                    TextButton.icon(
                      key: const Key('settings-avatar-remove-button'),
                      onPressed: _isSaving || _isProcessingPhoto
                          ? null
                          : () => setState(() {
                              _avatarUrl = '';
                              _error = null;
                            }),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus foto'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.coral,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens the system photo picker, downscales the pick to ≤256px / ≤~120KB,
  /// and stores it as a base64 data URL in the avatar field. The platform
  /// already pre-scales to 256px JPEG (quality 80); the encoder
  /// ([encodeAvatarDataUrl] behind [avatarEncoderProvider]) re-downscales in
  /// Dart whenever the platform couldn't compress the pick.
  Future<void> _pickPhoto() async {
    setState(() {
      _error = null;
      _isProcessingPhoto = true;
    });
    try {
      final picked = await ref
          .read(imagePickerProvider)
          .pickImage(
            source: ImageSource.gallery,
            maxWidth: kAvatarMaxDimension.toDouble(),
            maxHeight: kAvatarMaxDimension.toDouble(),
            imageQuality: 80,
          );
      if (picked == null) return; // User dismissed the picker.
      final dataUrl = await ref.read(avatarEncoderProvider)(
        await picked.readAsBytes(),
      );
      if (!mounted) return;
      if (dataUrl == null) {
        setState(
          () => _error = 'Foto tidak dapat diproses. Coba foto yang lain.',
        );
        return;
      }
      setState(() => _avatarUrl = dataUrl);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Foto tidak dapat dibuka. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isProcessingPhoto = false);
    }
  }

  /// Clears a lingering save-error banner once the user starts correcting the
  /// input (same pattern as the wallet invite sheet).
  void _clearError() {
    if (_error == null) return;
    setState(() => _error = null);
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
            avatarUrl: _avatarUrl,
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
