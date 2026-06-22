import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';

Transaction transactionFixture({
  required String id,
  required TransactionType type,
  required String walletId,
  required int amountMinor,
  required String note,
  required String transactionAt,
  String? categoryId,
  String? toWalletId,
}) {
  return Transaction(
    id: id,
    userId: '11111111-1111-1111-1111-111111111111',
    type: type,
    walletId: walletId,
    toWalletId: toWalletId,
    categoryId: categoryId,
    amountMinor: amountMinor,
    tagIds: const [],
    transactionAt: transactionAt,
    note: note,
    createdAt: transactionAt,
    updatedAt: transactionAt,
  );
}

const gopayWallet = Wallet(
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

const bcaWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220002',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'BCA Primary',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 15200000,
  color: 'blue',
  description: 'Main account',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const foodCategory = Category(
  id: '44444444-4444-4444-4444-444444440001',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Food & Dining',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const salaryCategory = Category(
  id: '33333333-3333-3333-3333-333333330001',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Salary',
  type: CategoryType.income,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

final groceriesTransaction = transactionFixture(
  id: '66666666-6666-6666-6666-666666660004',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 450000,
  note: 'Groceries at Indomaret',
  transactionAt: '2026-06-20T11:00:00Z',
);

final salaryTransaction = transactionFixture(
  id: '66666666-6666-6666-6666-666666660001',
  type: TransactionType.income,
  walletId: bcaWallet.id,
  categoryId: salaryCategory.id,
  amountMinor: 18500000,
  note: 'Monthly Salary',
  transactionAt: '2026-06-21T09:00:00Z',
);

final transferTransaction = transactionFixture(
  id: 'transfer',
  type: TransactionType.transfer,
  walletId: gopayWallet.id,
  toWalletId: bcaWallet.id,
  amountMinor: 250000,
  note: 'Move to savings',
  transactionAt: '2026-06-19T09:00:00Z',
);

final fuelTransaction = transactionFixture(
  id: 'fuel',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 350000,
  note: 'Fuel and Parking',
  transactionAt: '2026-06-18T09:00:00Z',
);

final coffeeTransaction = transactionFixture(
  id: 'coffee',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 35000,
  note: 'Coffee',
  transactionAt: '2026-06-17T09:00:00Z',
);

final lunchTransaction = transactionFixture(
  id: 'lunch',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 180000,
  note: 'Lunch Meeting',
  transactionAt: '2026-06-16T09:00:00Z',
);

final electricityTransaction = transactionFixture(
  id: 'electricity',
  type: TransactionType.expense,
  walletId: bcaWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 850000,
  note: 'Electricity Bill',
  transactionAt: '2026-06-15T09:00:00Z',
);

final entertainmentTransaction = transactionFixture(
  id: 'entertainment',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 250000,
  note: 'Movie Night',
  transactionAt: '2026-06-14T09:00:00Z',
);
