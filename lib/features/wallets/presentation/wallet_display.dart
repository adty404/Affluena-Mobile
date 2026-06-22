import 'package:flutter/material.dart';

import '../data/wallet_models.dart';

String walletTypeLabel(WalletType type) {
  return switch (type) {
    WalletType.cash => 'Cash',
    WalletType.bank => 'Bank',
    WalletType.eWallet => 'E-wallet',
    WalletType.investment => 'Investment',
    WalletType.goal => 'Goal',
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
  if (role == null || role.isEmpty) return 'Private';
  return role == 'owner' ? 'Owner' : _sentenceCase(role);
}

String walletStatusLabel(WalletShareStatus? status) {
  return switch (status) {
    WalletShareStatus.pending => 'Pending',
    WalletShareStatus.joined => 'Joined',
    WalletShareStatus.rejected => 'Rejected',
    null => 'Private',
  };
}

String memberStatusLabel(WalletShareStatus status) {
  return switch (status) {
    WalletShareStatus.pending => 'Pending',
    WalletShareStatus.joined => 'Joined',
    WalletShareStatus.rejected => 'Rejected',
  };
}

String walletKey(Wallet wallet) {
  return wallet.name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
}

String _sentenceCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
