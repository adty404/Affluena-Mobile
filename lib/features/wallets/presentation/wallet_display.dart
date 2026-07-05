import 'package:flutter/material.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../data/wallet_models.dart';

String walletTypeLabel(WalletType type) {
  return switch (type) {
    WalletType.cash => 'Tunai',
    WalletType.bank => 'Bank',
    WalletType.eWallet => 'E-wallet',
    WalletType.investment => 'Investasi',
    WalletType.goal => 'Target',
  };
}

IconData walletIcon(WalletType type) {
  return switch (type) {
    WalletType.cash => Icons.payments_outlined,
    WalletType.bank => Icons.account_balance_outlined,
    WalletType.eWallet => Icons.phone_iphone_outlined,
    WalletType.investment => Icons.trending_up,
    WalletType.goal => Icons.flag_outlined,
  };
}

String walletRoleLabel(String? role) {
  if (role == null || role.isEmpty) return 'Pribadi';
  return switch (role) {
    'owner' => 'Pemilik',
    'member' => 'Anggota',
    'viewer' => 'Hanya lihat',
    _ => _sentenceCase(role),
  };
}

String walletStatusLabel(WalletShareStatus? status) {
  return switch (status) {
    WalletShareStatus.pending => 'Menunggu',
    WalletShareStatus.joined => 'Tergabung',
    WalletShareStatus.rejected => 'Ditolak',
    null => 'Pribadi',
  };
}

String memberStatusLabel(WalletShareStatus status) {
  return switch (status) {
    WalletShareStatus.pending => 'Menunggu',
    WalletShareStatus.joined => 'Tergabung',
    WalletShareStatus.rejected => 'Ditolak',
  };
}

StatusTone memberStatusTone(WalletShareStatus status) {
  return switch (status) {
    WalletShareStatus.pending => StatusTone.warning,
    WalletShareStatus.joined => StatusTone.success,
    WalletShareStatus.rejected => StatusTone.danger,
  };
}

StatusTone walletShareTone(WalletShareStatus? status) {
  return switch (status) {
    WalletShareStatus.pending => StatusTone.warning,
    WalletShareStatus.joined => StatusTone.success,
    WalletShareStatus.rejected => StatusTone.danger,
    null => StatusTone.neutral,
  };
}

/// Formats an analytics month key (`YYYY-MM`) into a readable id_ID label
/// such as "Juni 2026". Falls back to the raw value if it cannot be parsed.
String walletMonthLabel(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length < 2) return monthKey;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) {
    return monthKey;
  }
  return AffluenaDateFormatter.monthLabelFull(DateTime(year, month));
}

/// Formats a [DateTime] into a readable id_ID month label such as "Juni 2026".
String walletMonthLabelFromDate(DateTime month) {
  return AffluenaDateFormatter.monthLabelFull(
    DateTime(month.year, month.month),
  );
}

/// Parses an analytics month key (`YYYY-MM`) into a [DateTime] at the first of
/// the month, or null when malformed.
DateTime? walletMonthDate(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length < 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return null;
  return DateTime(year, month);
}

/// Formats an ISO timestamp for display. Returns null when missing so callers
/// can hide the row entirely.
String? walletActivityLabel(String? isoString) {
  if (isoString == null || isoString.isEmpty) return null;
  try {
    return AffluenaDateFormatter.shortDate(isoString);
  } catch (_) {
    return isoString;
  }
}

String walletKey(Wallet wallet) {
  return wallet.name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
}

String _sentenceCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
