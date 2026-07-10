import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/csv_share_service.dart';
import '../application/insights_controller.dart';
import '../data/insight_models.dart';
import 'insight_shared_widgets.dart';

/// Pengaturan → Ekspor CSV — creating and re-sharing transaction CSV exports,
/// now a real standalone screen (previously the "Ekspor" chip inside the old
/// InsightsScreen).
class EksporScreen extends ConsumerWidget {
  const EksporScreen({super.key});

  static const path = '/ekspor';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);

    if (state.isLoading && state.exportJobs.isEmpty) {
      return const InsightsLoadingScaffold(title: 'Ekspor CSV');
    }

    if (state.loadError != null && state.exportJobs.isEmpty) {
      return InsightsErrorScaffold(
        title: 'Ekspor CSV',
        message: state.loadError!,
        onRetry: controller.load,
      );
    }

    return DrillInScaffold(
      title: 'Ekspor CSV',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          if (state.actionError != null) ...[
            AffluenaBanner.error(state.actionError!),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
          if (state.actionMessage != null) ...[
            AffluenaBanner.success(
              state.actionMessage!,
              onDismiss: controller.clearActionMessage,
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
          AffluenaCard(
            backgroundColor: context.affluenaColors.surfaceTintSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CSV transaksi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                Text(
                  'Buat ekspor transaksi bulan ini lalu bagikan atau simpan '
                  'berkas CSV-nya.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AffluenaSpacing.space4),
                FilledButton.icon(
                  key: const Key('insights-export-button'),
                  onPressed: state.isSaving ? null : controller.exportCsv,
                  icon: state.isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_outlined),
                  label: Text(state.isSaving ? 'Menyiapkan' : 'Ekspor CSV'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SectionHeader(
            title: 'Tugas ekspor',
            actionLabel: state.exportJobTotal == 0
                ? null
                : '${state.exportJobTotal} total',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.exportJobs.isEmpty)
            const InsightEmptyState(
              icon: Icons.file_download_outlined,
              title: 'Belum ada tugas ekspor',
              body: 'Ekspor CSV yang dibuat akan muncul di sini.',
            )
          else
            for (final job in state.exportJobs) ...[
              _ExportJobCard(job: job, controller: controller),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
        ],
      ),
    );
  }
}

class _ExportJobCard extends StatelessWidget {
  const _ExportJobCard({required this.job, required this.controller});

  final ExportJob job;
  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: () =>
          _openExportJobDetail(context, job: job, controller: controller),
      child: AffluenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.format.toUpperCase(),
                    style: textTheme.titleMedium,
                  ),
                ),
                StatusBadge.forStatus(job.status.name, label: job.status.label),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text('${job.rowCount} baris', style: textTheme.bodyLarge),
            const SizedBox(height: AffluenaSpacing.space1),
            Text(
              AffluenaDateFormatter.shortDate(job.createdAt),
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openExportJobDetail(
  BuildContext context, {
  required ExportJob job,
  required InsightsController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _ExportJobDetailSheet(job: job, controller: controller);
    },
  );
}

class _ExportJobDetailSheet extends StatefulWidget {
  const _ExportJobDetailSheet({required this.job, required this.controller});

  final ExportJob job;
  final InsightsController controller;

  @override
  State<_ExportJobDetailSheet> createState() => _ExportJobDetailSheetState();
}

class _ExportJobDetailSheetState extends State<_ExportJobDetailSheet> {
  bool _isSharing = false;
  bool _isRetrying = false;
  String? _error;

  Future<void> _share() async {
    setState(() {
      _isSharing = true;
      _error = null;
    });
    try {
      final outcome = await widget.controller.shareExportJob(widget.job);
      if (!mounted) return;
      switch (outcome) {
        case CsvShareOutcome.shared:
          Navigator.of(context).pop();
        case CsvShareOutcome.dismissed:
          setState(() => _isSharing = false);
        case CsvShareOutcome.unavailable:
          setState(() {
            _isSharing = false;
            _error = 'Berbagi tidak tersedia di perangkat ini.';
          });
        case CsvShareOutcome.empty:
          setState(() {
            _isSharing = false;
            _error = 'Ekspor ini sudah tidak punya baris untuk dibagikan.';
          });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSharing = false;
        _error = 'Ekspor tidak dapat dibagikan. Coba lagi.';
      });
    }
  }

  /// Re-submits a failed export with the same parameters (a fresh job is
  /// recorded server-side and the job list refreshed), then hands the new CSV
  /// to the share sheet so the retry immediately delivers the file.
  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
      _error = null;
    });
    try {
      final outcome = await widget.controller.retryExportJob(widget.job);
      if (!mounted) return;
      switch (outcome) {
        case CsvShareOutcome.shared:
        case CsvShareOutcome.dismissed:
          // The re-run succeeded; the refreshed list now shows the new job.
          Navigator.of(context).pop();
        case CsvShareOutcome.unavailable:
          setState(() {
            _isRetrying = false;
            _error =
                'Ekspor baru berhasil dibuat, tetapi berbagi tidak tersedia '
                'di perangkat ini.';
          });
        case CsvShareOutcome.empty:
          setState(() {
            _isRetrying = false;
            _error =
                'Rentang tanggal ini sudah tidak punya transaksi untuk '
                'diekspor.';
          });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
        _error = 'Ekspor ulang gagal. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final textTheme = Theme.of(context).textTheme;
    final canShare = job.status == ExportJobStatus.completed;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          0,
          AffluenaSpacing.space5,
          AffluenaSpacing.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ekspor ${job.format.toUpperCase()}',
                      style: textTheme.titleLarge,
                    ),
                  ),
                  StatusBadge.forStatus(
                    job.status.name,
                    label: job.status.label,
                  ),
                ],
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              InsightSheetDetailRow(
                row: InsightDetailRow('Baris', '${job.rowCount}'),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              InsightSheetDetailRow(
                row: InsightDetailRow(
                  'Dibuat',
                  AffluenaDateFormatter.shortDate(job.createdAt),
                ),
              ),
              if (job.fromAt != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                InsightSheetDetailRow(
                  row: InsightDetailRow(
                    'Dari',
                    AffluenaDateFormatter.shortDate(job.fromAt!),
                  ),
                ),
              ],
              if (job.toAt != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                InsightSheetDetailRow(
                  row: InsightDetailRow(
                    'Sampai',
                    AffluenaDateFormatter.shortDate(job.toAt!),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AffluenaSpacing.space4),
                AffluenaBanner.error(_error!),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              if (canShare)
                FilledButton.icon(
                  onPressed: _isSharing ? null : _share,
                  icon: _isSharing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_outlined),
                  label: Text(_isSharing ? 'Menyiapkan' : 'Unduh / bagikan'),
                )
              else ...[
                AffluenaBanner(
                  message:
                      'Ekspor ini gagal dibuat, jadi tidak ada berkas yang bisa '
                      'diunduh.',
                  tone: AffluenaBannerTone.warning,
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                FilledButton.icon(
                  key: const Key('export-job-retry-button'),
                  onPressed: _isRetrying ? null : _retry,
                  icon: _isRetrying
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isRetrying ? 'Mengulang ekspor' : 'Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
