import 'package:affluena_mobile/app/affluena_app.dart';
import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/core/storage/secure_token_store.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/auth/data/auth_repository.dart';
import 'package:affluena_mobile/features/budgets/data/budget_models.dart'
    show
        BudgetAlertsResponse,
        BudgetListResponse,
        BudgetReportResponse,
        BudgetReportSummary;
import 'package:affluena_mobile/features/budgets/data/budget_repository.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:affluena_mobile/features/goals/data/goal_models.dart';
import 'package:affluena_mobile/features/goals/data/goal_repository.dart';
import 'package:affluena_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:affluena_mobile/features/partner/data/partner_models.dart';
import 'package:affluena_mobile/features/partner/data/partner_repository.dart';
import 'package:affluena_mobile/features/quick_entry/data/quick_entry_models.dart';
import 'package:affluena_mobile/features/quick_entry/data/quick_entry_repository.dart';
import 'package:affluena_mobile/features/recurring/data/recurring_models.dart';
import 'package:affluena_mobile/features/recurring/data/recurring_repository.dart';
import 'package:affluena_mobile/features/settings/application/device_auth_service.dart';
import 'package:affluena_mobile/features/settings/data/security_preferences_repository.dart';
import 'package:affluena_mobile/features/tags/data/tag_models.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_models.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_repository.dart';
import 'package:affluena_mobile/features/transactions/data/split_bill_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget authTestApp({
  required MemoryTokenStore tokenStore,
  required FakeAuthRepository authRepository,
  SecurityPreferencesRepository? securityPreferencesRepository,
  DeviceAuthService? deviceAuthService,
  WalletRepository? walletRepository,
  CategoryRepository? categoryRepository,
  GoalRepository? goalRepository,
  BudgetRepository? budgetRepository,
  TrackerRepository? trackerRepository,
  RecurringRepository? recurringRepository,
  List<dynamic> extraOverrides = const [],
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      secureTokenStoreProvider.overrideWithValue(tokenStore),
      authRepositoryProvider.overrideWithValue(authRepository),
      dashboardRepositoryProvider.overrideWithValue(
        const FakeDashboardRepository(),
      ),
      transactionRepositoryProvider.overrideWithValue(
        const FakeTransactionRepository(),
      ),
      walletRepositoryProvider.overrideWithValue(
        walletRepository ?? const FakeWalletRepository(),
      ),
      categoryRepositoryProvider.overrideWithValue(
        categoryRepository ?? const FakeCategoryRepository(),
      ),
      // The redesign Beranda dashboard reads goals, budgets, installments,
      // subscriptions and recurring rules on mount; stub these repos so they
      // resolve to empty instead of attempting real network calls in tests.
      goalRepositoryProvider.overrideWithValue(
        goalRepository ?? const FakeGoalRepository(),
      ),
      budgetRepositoryProvider.overrideWithValue(
        budgetRepository ?? const FakeBudgetRepository(),
      ),
      trackerRepositoryProvider.overrideWithValue(
        trackerRepository ?? const FakeTrackerRepository(),
      ),
      recurringRepositoryProvider.overrideWithValue(
        recurringRepository ?? const FakeRecurringRepository(),
      ),
      partnerRepositoryProvider.overrideWithValue(
        const FakePartnerRepository(),
      ),
      tagRepositoryProvider.overrideWithValue(const FakeTagRepository()),
      quickEntryRepositoryProvider.overrideWithValue(
        const FakeQuickEntryRepository(),
      ),
      securityPreferencesRepositoryProvider.overrideWithValue(
        securityPreferencesRepository ?? MemorySecurityPreferencesRepository(),
      ),
      deviceAuthServiceProvider.overrideWithValue(
        deviceAuthService ?? FakeDeviceAuthService(),
      ),
      // These suites exercise auth/nav/dashboard/settings, not the first-run
      // onboarding gate, so boot straight past it into the normal flow.
      onboardingControllerProvider.overrideWith(
        CompletedOnboardingController.new,
      ),
      ...extraOverrides,
    ],
    child: const AffluenaApp(),
  );
}

/// An [OnboardingController] override that reports onboarding as already
/// completed so the router skips the first-run onboarding screen.
class CompletedOnboardingController extends OnboardingController {
  @override
  bool? build() => true;
}

Future<void> pumpAuthTestApp(
  WidgetTester tester, {
  MemoryTokenStore? tokenStore,
  FakeAuthRepository? authRepository,
  SecurityPreferencesRepository? securityPreferencesRepository,
  DeviceAuthService? deviceAuthService,
  WalletRepository? walletRepository,
  CategoryRepository? categoryRepository,
  GoalRepository? goalRepository,
  BudgetRepository? budgetRepository,
  TrackerRepository? trackerRepository,
  RecurringRepository? recurringRepository,
  List<dynamic> extraOverrides = const [],
}) async {
  // Date widgets (e.g. DateTimePickerField) format with the 'id_ID' locale,
  // mirroring main(); initialize it before pumping. Idempotent, so safe here.
  await initializeDateFormatting('id_ID');
  await tester.pumpWidget(
    authTestApp(
      tokenStore: tokenStore ?? MemoryTokenStore(),
      authRepository: authRepository ?? FakeAuthRepository(),
      securityPreferencesRepository: securityPreferencesRepository,
      deviceAuthService: deviceAuthService,
      walletRepository: walletRepository,
      categoryRepository: categoryRepository,
      goalRepository: goalRepository,
      budgetRepository: budgetRepository,
      trackerRepository: trackerRepository,
      recurringRepository: recurringRepository,
      extraOverrides: extraOverrides,
    ),
  );
  await tester.pumpAndSettle();
}

MemoryTokenStore authenticatedTokenStore() {
  return MemoryTokenStore(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );
}

DioException sessionExpiredDioException() {
  return DioException(
    requestOptions: RequestOptions(path: '/auth/me'),
    error: const SessionExpiredException(path: '/auth/me'),
    type: DioExceptionType.badResponse,
  );
}

class MemoryTokenStore extends SecureTokenStore {
  MemoryTokenStore({String? accessToken, String? refreshToken})
    : this._(MemoryTokenStorageBackend(), accessToken, refreshToken);

  MemoryTokenStore._(this.backend, String? accessToken, String? refreshToken)
    : super(backend) {
    backend.values['affluena.access_token'] = accessToken;
    backend.values['affluena.refresh_token'] = refreshToken;
  }

  final MemoryTokenStorageBackend backend;

  @override
  Future<String?> readAccessToken() {
    return backend.read(key: 'affluena.access_token');
  }

  @override
  Future<String?> readRefreshToken() {
    return backend.read(key: 'affluena.refresh_token');
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await backend.write(key: 'affluena.access_token', value: accessToken);
    await backend.write(key: 'affluena.refresh_token', value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await backend.delete(key: 'affluena.access_token');
    await backend.delete(key: 'affluena.refresh_token');
  }
}

class MemoryTokenStorageBackend implements TokenStorageBackend {
  final values = <String, String?>{};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

class MemorySecurityPreferencesRepository
    implements SecurityPreferencesRepository {
  MemorySecurityPreferencesRepository({
    SecurityPreferences initialPreferences = SecurityPreferences.disabled,
  }) : preferences = initialPreferences;

  SecurityPreferences preferences;
  final savedPreferences = <SecurityPreferences>[];

  @override
  Future<SecurityPreferences> load() async {
    return preferences;
  }

  @override
  Future<SecurityPreferences> save(SecurityPreferences nextPreferences) async {
    preferences = nextPreferences;
    savedPreferences.add(nextPreferences);
    return nextPreferences;
  }
}

class FakeDeviceAuthService implements DeviceAuthService {
  FakeDeviceAuthService({
    this.supported = true,
    this.authenticateResult = true,
  });

  bool supported;
  bool authenticateResult;
  int authenticateCalls = 0;

  @override
  Future<bool> isSupported() async {
    return supported;
  }

  @override
  Future<bool> authenticate() async {
    authenticateCalls += 1;
    return authenticateResult;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.meUser = demoUser,
    this.meError,
    this.loginSession = demoSession,
    this.loginError,
    List<AuthSessionRecord> sessions = const [seededAuthSession],
    this.updateAccountError,
    this.changePasswordError,
    this.changePasswordSession = demoSession,
    this.listSessionsError,
    this.revokeSessionError,
  }) {
    _seedSessions(sessions);
  }

  AuthUser? meUser;
  Object? meError;
  AuthSession? loginSession;
  Object? loginError;
  Object? updateAccountError;
  Object? changePasswordError;
  AuthSession changePasswordSession;
  Object? listSessionsError;
  Object? revokeSessionError;
  final List<AuthSessionRecord> sessions = [];
  final updateAccountRequests = <UpdateAccountRequest>[];
  final changePasswordRequests = <ChangePasswordRequest>[];
  final revokedSessionIds = <String>[];
  int meCalls = 0;
  int loginCalls = 0;
  int listSessionsCalls = 0;

  void _seedSessions(List<AuthSessionRecord> records) {
    sessions
      ..clear()
      ..addAll(records);
  }

  @override
  Future<AuthSession> login(LoginRequest request) async {
    loginCalls += 1;
    if (loginError != null) throw loginError!;
    return loginSession!;
  }

  @override
  Future<AuthSession> register(RegisterRequest request) async {
    return loginSession!;
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    return loginSession!;
  }

  @override
  Future<AuthUser> me() async {
    meCalls += 1;
    if (meError != null) throw meError!;
    return meUser!;
  }

  @override
  Future<AuthUser> updateAccount(UpdateAccountRequest request) async {
    updateAccountRequests.add(request);
    if (updateAccountError != null) throw updateAccountError!;
    final current = meUser ?? demoUser;
    final updated = AuthUser(
      id: current.id,
      email: current.email,
      name: request.name,
      avatarUrl: request.avatarUrl,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
    );
    meUser = updated;
    return updated;
  }

  @override
  Future<AuthSession> changePassword(ChangePasswordRequest request) async {
    changePasswordRequests.add(request);
    if (changePasswordError != null) throw changePasswordError!;
    return changePasswordSession;
  }

  @override
  Future<List<AuthSessionRecord>> listSessions() async {
    listSessionsCalls += 1;
    if (listSessionsError != null) throw listSessionsError!;
    return sessions;
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    revokedSessionIds.add(sessionId);
    if (revokeSessionError != null) throw revokeSessionError!;
    sessions.removeWhere((session) => session.id == sessionId);
  }

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {}
}

class FakeDashboardRepository implements DashboardRepository {
  const FakeDashboardRepository({this.summaryResponse = seededSummary});

  final DashboardSummary summaryResponse;

  @override
  Future<DashboardSummary> summary({String? month}) async {
    return summaryResponse;
  }

  @override
  Future<CashflowTrendResponse> cashflowTrend({
    int? months,
    String? granularity,
    int? weeks,
    String? from,
    String? to,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ExpenseDistributionResponse> expenseDistribution({String? month}) {
    throw UnimplementedError();
  }

  @override
  Future<DashboardForecast> forecast({String? month}) {
    throw UnimplementedError();
  }
}

class FakeTransactionRepository implements TransactionRepository {
  const FakeTransactionRepository({
    this.transactions = const [seededTransaction],
  });

  final List<Transaction> transactions;

  @override
  Future<TransactionListResponse> listTransactions({
    TransactionType? type,
    String? walletId,
    String? categoryId,
    String? tagId,
    String? from,
    String? to,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return TransactionListResponse(
      transactions: transactions,
      pagination: Pagination(
        total: transactions.length,
        limit: limit ?? transactions.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Transaction> getTransaction(String id) async {
    return transactions.firstWhere((transaction) => transaction.id == id);
  }

  @override
  Future<Transaction> createTransaction(TransactionRequest request) async {
    return transactions.first;
  }

  @override
  Future<SplitTransactionResponse> splitBill(
    SplitTransactionRequest request,
  ) async {
    return const SplitTransactionResponse(
      transactionId: 'transaction-split',
      debtIds: [],
    );
  }

  @override
  Future<SplitBillListResponse> listSplitBills({String? status}) async {
    return const SplitBillListResponse(splitBills: []);
  }

  @override
  Future<SplitBillDetail> getSplitBill(String transactionId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTransaction(String id) async {}
}

class FakeQuickEntryRepository implements QuickEntryRepository {
  const FakeQuickEntryRepository({this.templates = const [seededTemplate]});

  final List<QuickEntryTemplate> templates;

  @override
  Future<QuickEntryTemplateListResponse> listTemplates({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return QuickEntryTemplateListResponse(
      templates: templates,
      pagination: Pagination(
        total: templates.length,
        limit: limit ?? templates.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<QuickEntryTemplate> getTemplate(String id) async {
    return templates.firstWhere((template) => template.id == id);
  }

  @override
  Future<QuickEntryTemplate> createTemplate(
    QuickEntryTemplateRequest request,
  ) async {
    return templates.first;
  }

  @override
  Future<QuickEntryTemplate> updateTemplate(
    String id,
    QuickEntryTemplateRequest request,
  ) async {
    return templates.firstWhere((template) => template.id == id);
  }

  @override
  Future<void> deleteTemplate(String id) async {}

  @override
  Future<ExecuteQuickEntryResponse> executeTemplate(
    String id,
    ExecuteQuickEntryRequest request,
  ) async {
    return const ExecuteQuickEntryResponse(transaction: seededTransaction);
  }
}

class FakeWalletRepository implements WalletRepository {
  const FakeWalletRepository({this.wallets = const [seededWallet]});

  final List<Wallet> wallets;

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
    return wallets.first;
  }

  @override
  Future<Wallet> getWallet(String id) async {
    return wallets.firstWhere((wallet) => wallet.id == id);
  }

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    return wallets.firstWhere((wallet) => wallet.id == id);
  }

  @override
  Future<void> deleteWallet(String id) async {}

  @override
  Future<WalletInviteResponse> inviteMember(
    String id,
    WalletInviteRequest request,
  ) async {
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
    final wallet = await getWallet(id);
    return WalletMembersResponse(members: wallet.members);
  }

  @override
  Future<WalletAnalytics> getAnalytics(String id, {String? month}) async {
    return WalletAnalytics(
      walletId: id,
      month: month ?? '2026-06',
      inflowMinor: 0,
      outflowMinor: 0,
      transactionCount: 0,
    );
  }
}

class FakeCategoryRepository implements CategoryRepository {
  const FakeCategoryRepository({this.categories = const [seededCategory]});

  final List<Category> categories;

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return CategoryListResponse(
      categories: categories,
      pagination: Pagination(
        total: categories.length,
        limit: limit ?? categories.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async {
    return categories.first;
  }

  @override
  Future<Category> getCategory(String id) async {
    return categories.firstWhere((category) => category.id == id);
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return categories.firstWhere((category) => category.id == id);
  }

  @override
  Future<void> deleteCategory(String id) async {}
}

class FakeGoalRepository implements GoalRepository {
  const FakeGoalRepository();

  @override
  Future<GoalListResponse> listGoals() async {
    return const GoalListResponse(goals: []);
  }

  @override
  Future<Goal> getGoal(String id) => throw UnimplementedError();

  @override
  Future<Goal> createGoal(GoalRequest request) => throw UnimplementedError();

  @override
  Future<Goal> updateGoal(String id, GoalRequest request) =>
      throw UnimplementedError();

  @override
  Future<Goal> updateGoalStatus(String id, GoalStatusRequest request) =>
      throw UnimplementedError();

  @override
  Future<void> inviteMember(String id, GoalInviteRequest request) async {}

  @override
  Future<void> respondInvite(
    String id,
    String userId,
    GoalInviteResponseRequest request,
  ) async {}
}

/// Empty-result fakes for the dashboard's extra sections. Only the read methods
/// the controllers call on mount are implemented; the rest route through
/// [noSuchMethod] (never exercised by these suites).
class FakeBudgetRepository implements BudgetRepository {
  const FakeBudgetRepository();

  @override
  Future<BudgetListResponse> listBudgets({
    String? month,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return BudgetListResponse(
      budgets: const [],
      pagination: Pagination(total: 0, limit: limit ?? 0, offset: offset ?? 0),
    );
  }

  @override
  Future<BudgetAlertsResponse> getAlerts({String? month}) async {
    return const BudgetAlertsResponse(alerts: []);
  }

  @override
  Future<BudgetReportResponse> getReport({String? month}) async {
    return const BudgetReportResponse(
      report: [],
      summary: BudgetReportSummary(
        totalLimitMinor: 0,
        totalSpentMinor: 0,
        totalRemainingMinor: 0,
        safeCount: 0,
        warningCount: 0,
        exceededCount: 0,
        dailyAllowanceMinor: 0,
        forecastMinor: 0,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTrackerRepository implements TrackerRepository {
  const FakeTrackerRepository();

  @override
  Future<InstallmentListResponse> listInstallments({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return InstallmentListResponse(
      installments: const [],
      pagination: Pagination(total: 0, limit: limit ?? 0, offset: offset ?? 0),
    );
  }

  @override
  Future<SubscriptionListResponse> listSubscriptions({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return SubscriptionListResponse(
      subscriptions: const [],
      pagination: Pagination(total: 0, limit: limit ?? 0, offset: offset ?? 0),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRecurringRepository implements RecurringRepository {
  const FakeRecurringRepository();

  @override
  Future<RecurringRuleListResponse> listRules({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return RecurringRuleListResponse(
      rules: const [],
      pagination: Pagination(total: 0, limit: limit ?? 0, offset: offset ?? 0),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePartnerRepository implements PartnerRepository {
  const FakePartnerRepository();

  @override
  Future<PartnerListResponse> list() async {
    return const PartnerListResponse(partners: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTagRepository implements TagRepository {
  const FakeTagRepository({this.tags = const [seededTag]});

  final List<Tag> tags;

  @override
  Future<TagListResponse> listTags({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return TagListResponse(
      tags: tags,
      pagination: Pagination(
        total: tags.length,
        limit: limit ?? tags.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Tag> createTag(TagRequest request) async {
    return tags.first;
  }

  @override
  Future<Tag> getTag(String id) async {
    return tags.firstWhere((tag) => tag.id == id);
  }

  @override
  Future<Tag> updateTag(String id, TagRequest request) async {
    return tags.firstWhere((tag) => tag.id == id);
  }

  @override
  Future<void> deleteTag(String id) async {}
}

const demoUser = AuthUser(
  id: '11111111-1111-1111-1111-111111111111',
  email: 'demo@affluena.com',
  name: 'Demo User',
  avatarUrl: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const demoSession = AuthSession(
  user: demoUser,
  tokens: AuthTokens(
    accessToken: 'fresh-access-token',
    refreshToken: 'fresh-refresh-token',
  ),
);

const seededAuthSession = AuthSessionRecord(
  id: '99999999-9999-9999-9999-999999990001',
  userId: '11111111-1111-1111-1111-111111111111',
  tokenSuffix: 'ab12',
  userAgent: 'Chrome on macOS',
  ipAddress: '127.0.0.1',
  expiresAt: '2026-06-30T10:00:00Z',
  createdAt: '2026-06-21T10:00:00Z',
  lastUsedAt: '2026-06-21T11:00:00Z',
);

const seededSummary = DashboardSummary(
  month: '2026-06',
  netWorthMinor: 16370000,
  monthlyIncomeMinor: 21000000,
  monthlyExpenseMinor: 3300000,
  monthlyCashflowMinor: 17700000,
  budget: BudgetSummary(
    limitMinor: 1000000,
    spentMinor: 720000,
    remainingMinor: 280000,
    usagePercent: 72,
  ),
  upcomingSubscriptions: [],
  upcomingInstallments: [],
  upcomingDebts: [],
);

const seededWalletId = '22222222-2222-2222-2222-222222220003';
const seededCategoryId = '44444444-4444-4444-4444-444444440001';

const seededWallet = Wallet(
  id: seededWalletId,
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

const seededCategory = Category(
  id: seededCategoryId,
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Food & Dining',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const seededTag = Tag(
  id: '55555555-5555-5555-5555-555555550002',
  userId: '11111111-1111-1111-1111-111111111111',
  name: '#MonthlyBill',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const seededTransaction = Transaction(
  id: '66666666-6666-6666-6666-666666660001',
  userId: '11111111-1111-1111-1111-111111111111',
  type: TransactionType.expense,
  walletId: seededWalletId,
  categoryId: seededCategoryId,
  amountMinor: 125000,
  tagIds: [],
  transactionAt: '2026-06-21T10:00:00Z',
  note: 'Lunch meeting',
  createdAt: '2026-06-21T10:00:00Z',
  updatedAt: '2026-06-21T10:00:00Z',
);

const seededTemplate = QuickEntryTemplate(
  id: '77777777-7777-7777-7777-777777770001',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Daily Coffee',
  type: TransactionType.expense,
  walletId: seededWalletId,
  categoryId: seededCategoryId,
  amountMinor: 35000,
  note: 'Daily Coffee',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
