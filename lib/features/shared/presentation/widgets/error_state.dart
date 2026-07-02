import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../../app/theme/sky_palette.dart';

/// The app-wide load-error state: an icon, a friendly Bahasa Indonesia
/// message, and a "Coba lagi" retry. Callers pass fixed copy — never a raw
/// API/exception string.
///
/// Colours come from the Tinta `context.sky.*` tokens (which resolve to the
/// same monochrome palette the `affluenaColors` feature screens use).
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.onRetry,
    this.message = 'Tidak bisa memuat data. Coba lagi, ya.',
    super.key,
  }) : _compact = false;

  /// Compact single-row variant for inline sections (message · retry) so a
  /// failed section stays quiet instead of dominating the screen.
  const ErrorState.compact({
    required this.onRetry,
    this.message = 'Gagal memuat.',
    super.key,
  }) : _compact = true;

  final VoidCallback onRetry;
  final String message;
  final bool _compact;

  static const _retryLabel = 'Coba lagi';

  @override
  Widget build(BuildContext context) {
    return _compact ? _buildCompact(context) : _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    final sky = context.sky;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AffluenaSpacing.space4,
        vertical: AffluenaSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 40, color: sky.faint),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: sky.muted),
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(_retryLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final sky = context.sky;
    return Container(
      decoration: BoxDecoration(
        color: sky.sheet,
        border: Border.all(color: sky.line),
        borderRadius: BorderRadius.circular(AffluenaRadii.control),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AffluenaSpacing.space3,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: sky.muted),
          const SizedBox(width: AffluenaSpacing.space2),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, color: sky.muted),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: sky.accent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(_retryLabel),
          ),
        ],
      ),
    );
  }
}
