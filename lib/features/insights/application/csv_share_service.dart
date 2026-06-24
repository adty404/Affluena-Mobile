import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/insight_models.dart';

final csvShareServiceProvider = Provider<CsvShareService>((ref) {
  return const CsvShareService();
});

/// The outcome of routing a [CsvExportResult] through the platform share sheet.
enum CsvShareOutcome {
  /// The file was shared or saved to a destination the user picked.
  shared,

  /// The user dismissed the share sheet without choosing a destination.
  dismissed,

  /// No sharing target was available on this platform.
  unavailable,

  /// The export produced no rows, so there was nothing to share.
  empty,
}

/// Writes CSV export bytes to a temporary file and hands it to the platform
/// share sheet. Kept separate from the controller so the success message can be
/// driven by a *real* share/save outcome rather than the network call alone.
class CsvShareService {
  const CsvShareService();

  Future<CsvShareOutcome> share(CsvExportResult export) async {
    final directory = await getTemporaryDirectory();
    final safeName = _sanitizeFilename(export.filename);
    final file = File('${directory.path}/$safeName');
    await file.writeAsBytes(export.bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv', name: safeName)],
        fileNameOverrides: [safeName],
        subject: safeName,
      ),
    );

    return switch (result.status) {
      ShareResultStatus.success => CsvShareOutcome.shared,
      ShareResultStatus.dismissed => CsvShareOutcome.dismissed,
      ShareResultStatus.unavailable => CsvShareOutcome.unavailable,
    };
  }
}

String _sanitizeFilename(String filename) {
  final trimmed = filename.trim();
  final cleaned = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (cleaned.isEmpty) return 'transactions_export.csv';
  return cleaned.toLowerCase().endsWith('.csv') ? cleaned : '$cleaned.csv';
}
