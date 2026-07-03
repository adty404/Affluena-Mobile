import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:affluena_mobile/features/wallets/presentation/wallets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget walletsTestApp(WalletRepository walletRepository) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [walletRepositoryProvider.overrideWithValue(walletRepository)],
    child: const MaterialApp(home: Scaffold(body: WalletsScreen())),
  );
}

class TestWalletRepository implements WalletRepository {
  TestWalletRepository({
    required List<Wallet> wallets,
    this.createError,
    this.updateError,
    this.getError,
    this.inviteError,
    this.deleteError,
    this.analytics,
  }) : wallets = List<Wallet>.of(wallets);

  final List<Wallet> wallets;
  final Object? createError;
  final Object? updateError;
  final Object? getError;
  final Object? inviteError;
  final Object? deleteError;
  final WalletAnalytics? analytics;
  final createRequests = <WalletRequest>[];
  final updateIds = <String>[];
  final updateRequests = <WalletRequest>[];
  final getWalletIds = <String>[];
  final memberWalletIds = <String>[];
  final analyticsWalletIds = <String>[];
  final inviteWalletIds = <String>[];
  final inviteRequests = <WalletInviteRequest>[];
  final deletedIds = <String>[];

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return WalletListResponse(
      wallets: wallets,
      pagination: Pagination(
        total: wallets.length,
        limit: limit ?? wallets.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) async {
    createRequests.add(request);
    if (createError != null) throw createError!;
    final wallet = Wallet(
      id: 'created-${createRequests.length}',
      userId: cashWallet.userId,
      name: request.name,
      type: request.type,
      currencyCode: request.currencyCode,
      balanceMinor: request.balanceMinor ?? 0,
      color: request.color ?? '',
      description: request.description ?? '',
      createdAt: '2026-06-22T00:00:00Z',
      updatedAt: '2026-06-22T00:00:00Z',
    );
    wallets.add(wallet);
    return wallet;
  }

  @override
  Future<Wallet> getWallet(String id) async {
    getWalletIds.add(id);
    if (getError != null) throw getError!;
    return wallets.firstWhere((wallet) => wallet.id == id);
  }

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    updateIds.add(id);
    updateRequests.add(request);
    if (updateError != null) throw updateError!;
    final index = wallets.indexWhere((wallet) => wallet.id == id);
    final current = wallets[index];
    final wallet = Wallet(
      id: current.id,
      userId: current.userId,
      name: request.name,
      type: request.type,
      currencyCode: request.currencyCode,
      balanceMinor: current.balanceMinor,
      color: request.color ?? current.color,
      description: request.description ?? current.description,
      goalId: current.goalId,
      role: current.role,
      shareStatus: current.shareStatus,
      members: current.members,
      createdAt: current.createdAt,
      updatedAt: '2026-06-22T00:00:00Z',
    );
    wallets[index] = wallet;
    return wallet;
  }

  @override
  Future<void> deleteWallet(String id) async {
    deletedIds.add(id);
    if (deleteError != null) throw deleteError!;
    wallets.removeWhere((wallet) => wallet.id == id);
  }

  @override
  Future<WalletInviteResponse> inviteMember(
    String id,
    WalletInviteRequest request,
  ) async {
    inviteWalletIds.add(id);
    inviteRequests.add(request);
    if (inviteError != null) throw inviteError!;
    final index = wallets.indexWhere((wallet) => wallet.id == id);
    if (index != -1) {
      final wallet = wallets[index];
      wallets[index] = Wallet(
        id: wallet.id,
        userId: wallet.userId,
        name: wallet.name,
        type: wallet.type,
        currencyCode: wallet.currencyCode,
        balanceMinor: wallet.balanceMinor,
        color: wallet.color,
        description: wallet.description,
        goalId: wallet.goalId,
        role: wallet.role,
        shareStatus: wallet.shareStatus,
        members: [
          ...wallet.members,
          WalletMember(
            walletId: wallet.id,
            userId: 'invited-${inviteRequests.length}',
            email: request.email,
            role: 'viewer',
            status: WalletShareStatus.pending,
            createdAt: '2026-06-22T00:00:00Z',
            updatedAt: '2026-06-22T00:00:00Z',
          ),
        ],
        createdAt: wallet.createdAt,
        updatedAt: '2026-06-22T00:00:00Z',
      );
    }
    return const WalletInviteResponse(status: WalletShareStatus.pending);
  }

  @override
  Future<WalletInviteResponse> respondInvite(
    String id,
    String memberId,
    WalletInviteResponse response,
  ) async {
    return response;
  }

  @override
  Future<WalletMembersResponse> listMembers(String id) async {
    memberWalletIds.add(id);
    final wallet = await getWallet(id);
    return WalletMembersResponse(members: wallet.members);
  }

  @override
  Future<WalletAnalytics> getAnalytics(String id, {String? month}) async {
    analyticsWalletIds.add(id);
    return analytics ??
        WalletAnalytics(
          walletId: id,
          month: month ?? '2026-06',
          inflowMinor: 0,
          outflowMinor: 0,
          transactionCount: 0,
        );
  }
}

const cashWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220001',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Cash Wallet',
  type: WalletType.cash,
  currencyCode: 'IDR',
  balanceMinor: 850000,
  color: 'gray',
  description: 'Pocket cash',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const bankWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220002',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'BCA Primary',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 15200000,
  color: 'blue',
  description: 'Main account',
  role: 'owner',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const goPayWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220003',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 320000,
  color: 'green',
  description: 'Daily wallet',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

/// Carries a parseable palette hex, so its card renders the solid colored
/// treatment (the other fixtures keep legacy non-hex color strings).
const greenWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220004',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Dompet Hijau',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 1000000,
  color: '#2E8B57',
  description: 'Tabungan utama',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const goalWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220099',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Europe Trip Fund',
  type: WalletType.goal,
  currencyCode: 'IDR',
  balanceMinor: 8500000,
  color: 'purple',
  description: '17% of Rp 50.000.000 target',
  goalId: 'goal-wallet',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
