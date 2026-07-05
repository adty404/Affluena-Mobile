import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../application/partner_controller.dart';
import '../data/partner_models.dart';

/// Settings → "Berbagi Dompet": invite a Pemantau (by email) who can then view
/// ALL of your wallets (read-only, max 5, one-way), plus accept/reject the
/// wallets others invite you to view. (Internal names stay `partner`/`Partner`
/// and the endpoints are the historical `/api/v1/partners` — see the API repo.)
class PartnerScreen extends ConsumerStatefulWidget {
  const PartnerScreen({super.key});

  static const path = '/partner';

  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(partnerControllerProvider.notifier).invite(email);
    if (!mounted) return;
    if (ok) {
      _emailController.clear();
      FocusScope.of(context).unfocus();
      messenger.showSnackBar(
        const SnackBar(content: Text('Undangan terkirim.')),
      );
    }
  }

  Future<void> _revoke(PartnerLink link) async {
    final ok = await skyConfirm(
      context,
      title: 'Hapus pemantau',
      message:
          '${link.displayName} tidak akan bisa lagi melihat dompetmu. Lanjutkan?',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (ok && mounted) {
      await ref.read(partnerControllerProvider.notifier).revoke(link.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnerControllerProvider);

    return DrillInScaffold(
      title: 'Berbagi Dompet',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          Text(
            'Undang maksimal ${PartnerState.maxShares} orang untuk melihat '
            'semua riwayat dompetmu (hanya lihat, termasuk dompet baru). '
            'Mereka tidak bisa mengubah apa pun.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: context.sky.muted,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          // Up to maxShares viewers: hide the invite field once the limit is
          // reached, replacing it with a hint to remove someone first.
          if (state.canInvite)
            _InviteCard(
              controller: _emailController,
              busy: state.isSaving,
              error: state.actionError,
              onSubmit: _invite,
              onChanged: () => ref
                  .read(partnerControllerProvider.notifier)
                  .clearActionError(),
            )
          else
            const _LimitNote(),
          if (state.incomingPending.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            _SectionTitle('Undangan masuk'),
            const SizedBox(height: AffluenaSpacing.space3),
            for (final link in state.incomingPending)
              Padding(
                padding: const EdgeInsets.only(bottom: AffluenaSpacing.space3),
                child: _IncomingRow(
                  link: link,
                  busy: state.isSaving,
                  onAccept: () => ref
                      .read(partnerControllerProvider.notifier)
                      .respond(link.id, 'joined'),
                  onReject: () => ref
                      .read(partnerControllerProvider.notifier)
                      .respond(link.id, 'rejected'),
                ),
              ),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          _SectionTitle(
            'Pemantau saya (${state.activeShareCount}/${PartnerState.maxShares})',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.isLoading && state.links.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AffluenaSpacing.space5),
                child: CircularProgressIndicator(color: context.sky.accent),
              ),
            )
          else if (state.owned.isEmpty)
            Text(
              'Belum ada yang kamu undang. Tambahkan lewat email di atas.',
              style: TextStyle(fontSize: 12.5, color: context.sky.muted),
            )
          else
            for (final link in state.owned)
              Padding(
                padding: const EdgeInsets.only(bottom: AffluenaSpacing.space3),
                child: _OwnedRow(
                  link: link,
                  busy: state.isSaving,
                  onRevoke: () => _revoke(link),
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: context.sky.ink,
      ),
    );
  }
}

class _LimitNote extends StatelessWidget {
  const _LimitNote();

  @override
  Widget build(BuildContext context) {
    return SkyDetailCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: context.sky.muted),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Text(
              'Kamu sudah berbagi dengan 5 orang (batas maksimal). Hapus '
              'salah satu di bawah untuk menambah yang lain.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.sky.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.controller,
    required this.busy,
    required this.error,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;

  /// Fired on every keystroke so the screen can clear a stale invite error
  /// while the user corrects the email (wallet-invite-sheet pattern).
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AffluenaRadii.control);
    return SkyDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Undang lewat email',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.sky.muted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'email@contoh.com',
              filled: true,
              fillColor: context.sky.sheet,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AffluenaSpacing.space4,
                vertical: 14,
              ),
              prefixIcon: Icon(
                Icons.mail_outline,
                size: 18,
                color: context.sky.faint,
              ),
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: context.sky.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: context.sky.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: BorderSide(color: context.sky.accent, width: 1.6),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AffluenaSpacing.space2),
            Text(
              error!,
              style: TextStyle(fontSize: 12, color: context.sky.danger),
            ),
          ],
          const SizedBox(height: AffluenaSpacing.space3),
          FilledButton(
            onPressed: busy ? null : onSubmit,
            child: const Text('Undang'),
          ),
        ],
      ),
    );
  }
}

class _OwnedRow extends StatelessWidget {
  const _OwnedRow({
    required this.link,
    required this.busy,
    required this.onRevoke,
  });

  final PartnerLink link;
  final bool busy;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (link.status) {
      'joined' => ('Terhubung', context.sky.income),
      'pending' => ('Menunggu', context.sky.muted),
      _ => ('Ditolak', context.sky.faint),
    };
    return SkyDetailCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.sky.ink,
                  ),
                ),
                const SizedBox(height: 2),
                SkyStatusPill(label: label, color: color),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : onRevoke,
            style: TextButton.styleFrom(foregroundColor: context.sky.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _IncomingRow extends StatelessWidget {
  const _IncomingRow({
    required this.link,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final PartnerLink link;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return SkyDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${link.displayName} ingin berbagi dompetnya denganmu.',
            style: TextStyle(fontSize: 13.5, color: context.sky.ink),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  child: const Text('Tolak'),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
                  child: const Text('Terima'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
