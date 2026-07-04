import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/state/copy_with_sentinel.dart';
import '../../shared/application/financial_refresh.dart';
import '../../wallets/application/wallets_controller.dart';
import '../data/partner_models.dart';
import '../data/partner_repository.dart';

final partnerControllerProvider =
    NotifierProvider<PartnerController, PartnerState>(PartnerController.new);

class PartnerState {
  const PartnerState({
    this.links = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
  });

  final List<PartnerLink> links;
  final bool isLoading;
  final bool isSaving;
  final String? loadError;
  final String? actionError;

  /// Links I created — partners who can view my wallets.
  List<PartnerLink> get owned =>
      links.where((l) => l.isOwned).toList(growable: false);

  /// Maximum number of people I can share my wallets with at once.
  static const maxShares = 5;

  /// People I'm actively sharing with (pending or joined invites).
  int get activeShareCount =>
      owned.where((l) => l.isPending || l.isJoined).length;

  /// I can still invite more viewers (below the limit).
  bool get canInvite => activeShareCount < maxShares;

  /// Incoming invites still awaiting my response.
  List<PartnerLink> get incomingPending =>
      links.where((l) => l.isIncoming && l.isPending).toList(growable: false);

  /// Owner ids whose wallets I can currently view (accepted incoming links).
  Set<String> get viewableOwnerIds => links
      .where((l) => l.isIncoming && l.isJoined)
      .map((l) => l.userId)
      .toSet();

  PartnerState copyWith({
    List<PartnerLink>? links,
    bool? isLoading,
    bool? isSaving,
    Object? loadError = kUnchanged,
    Object? actionError = kUnchanged,
  }) {
    return PartnerState(
      links: links ?? this.links,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      loadError: identical(loadError, kUnchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, kUnchanged)
          ? this.actionError
          : actionError as String?,
    );
  }
}

class PartnerController extends Notifier<PartnerState> {
  @override
  PartnerState build() {
    Future<void>.microtask(load);
    return const PartnerState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null, actionError: null);
    try {
      final response = await ref.read(partnerRepositoryProvider).list();
      state = state.copyWith(isLoading: false, links: response.partners);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Daftar berbagi gagal dimuat.',
      );
    }
  }

  Future<bool> invite(String email) => _mutate(
    () => ref
        .read(partnerRepositoryProvider)
        .invite(PartnerInviteRequest(email: email.trim())),
    onError: _inviteErrorMessage,
  );

  String _inviteErrorMessage(Object error) {
    final api = _asApiException(error);
    switch (api?.statusCode) {
      case 404:
        return 'Email itu belum terdaftar di Affluena.';
      case 409:
        return 'Kamu sudah berbagi dengan 5 orang (maksimal). '
            'Hapus salah satu dulu untuk menambah.';
      case 400:
        return 'Tidak bisa mengundang dirimu sendiri.';
    }
    return api?.message ?? 'Undangan gagal dikirim.';
  }

  ApiException? _asApiException(Object error) {
    if (error is ApiException) return error;
    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }
    return null;
  }

  /// Clears a lingering action error once the user starts correcting the
  /// input, so a stale banner never sits next to a fresh email.
  void clearActionError() {
    if (state.actionError == null) return;
    state = state.copyWith(actionError: null);
  }

  Future<bool> respond(String id, String status) => _mutate(
    () => ref
        .read(partnerRepositoryProvider)
        .respond(id, PartnerRespondRequest(status: status)),
  );

  Future<bool> revoke(String id) =>
      _mutate(() => ref.read(partnerRepositoryProvider).revoke(id));

  Future<bool> _mutate(
    Future<void> Function() action, {
    String Function(Object error)? onError,
  }) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await action();
      // Responding to / revoking a share changes which wallets are visible to
      // whom, so refresh the wallet list + every balance surface. This keeps
      // the partner list and the wallet "Dibagikan untukku" list from drifting
      // (the mirror of wallet_members_controller reloading the partner list).
      ref
        ..invalidate(walletListProvider)
        ..invalidateBalances();
      state = state.copyWith(isSaving: false);
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        actionError: onError?.call(error) ?? 'Tindakan itu gagal diselesaikan.',
      );
      return false;
    }
  }
}
