import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';
import 'wallet_detail_controller.dart';
import 'wallets_controller.dart';

/// Drives accept/reject responses to a wallet invitation. Tracks which member
/// row is in-flight so each row can show its own loading state, and surfaces a
/// human-readable error without tearing down the screen.
final walletMembersControllerProvider =
    NotifierProvider.family<
      WalletMembersController,
      WalletMembersActionState,
      String
    >((walletId) => WalletMembersController(walletId));

class WalletMembersActionState {
  const WalletMembersActionState({this.pendingUserId, this.error});

  /// The `userId` of the member whose response is currently being submitted.
  final String? pendingUserId;
  final String? error;

  bool isPending(String userId) => pendingUserId == userId;

  WalletMembersActionState copyWith({
    String? pendingUserId,
    String? error,
    bool clearPending = false,
    bool clearError = false,
  }) {
    return WalletMembersActionState(
      pendingUserId: clearPending
          ? null
          : (pendingUserId ?? this.pendingUserId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WalletMembersController extends Notifier<WalletMembersActionState> {
  WalletMembersController(this._walletId);

  final String _walletId;

  @override
  WalletMembersActionState build() {
    return const WalletMembersActionState();
  }

  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(clearError: true);
  }

  /// Responds to an invitation with [status] (joined or rejected). Returns true
  /// on success. Errors are stored on state rather than thrown.
  Future<bool> respond(WalletMember member, WalletShareStatus status) async {
    if (state.pendingUserId != null) return false;

    state = WalletMembersActionState(pendingUserId: member.userId);
    try {
      await ref
          .read(walletRepositoryProvider)
          .respondInvite(
            _walletId,
            member.userId,
            WalletInviteResponse(status: status),
          );
      ref
        ..invalidate(walletDetailProvider(_walletId))
        ..invalidate(walletListProvider);
      state = const WalletMembersActionState();
      return true;
    } catch (error) {
      state = WalletMembersActionState(error: _errorMessage(error, status));
      return false;
    }
  }

  String _errorMessage(Object error, WalletShareStatus status) {
    final fallback = status == WalletShareStatus.joined
        ? 'Undangan gagal diterima.'
        : 'Undangan gagal ditolak.';
    if (error is ApiException) return error.message;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner.message;
    }
    return fallback;
  }
}
