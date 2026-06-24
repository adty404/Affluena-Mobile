import '../../../core/api/api_json.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.month,
    required this.netWorthMinor,
    required this.monthlyIncomeMinor,
    required this.monthlyExpenseMinor,
    required this.monthlyCashflowMinor,
    required this.budget,
    required this.upcomingSubscriptions,
    required this.upcomingInstallments,
    required this.upcomingDebts,
  });

  factory DashboardSummary.fromJson(JsonMap json) {
    return DashboardSummary(
      month: ApiJson.readString(json, 'month'),
      netWorthMinor: ApiJson.readInt(json, 'net_worth_minor'),
      monthlyIncomeMinor: ApiJson.readInt(json, 'monthly_income_minor'),
      monthlyExpenseMinor: ApiJson.readInt(json, 'monthly_expense_minor'),
      monthlyCashflowMinor: ApiJson.readInt(json, 'monthly_cashflow_minor'),
      budget: BudgetSummary.fromJson(ApiJson.readMap(json, 'budget')),
      upcomingSubscriptions: ApiJson.readObjectList(
        json,
        'upcoming_subscriptions',
      ).map(UpcomingSubscription.fromJson).toList(growable: false),
      upcomingInstallments: ApiJson.readObjectList(
        json,
        'upcoming_installments',
      ).map(UpcomingInstallment.fromJson).toList(growable: false),
      upcomingDebts: ApiJson.readObjectList(
        json,
        'upcoming_debts',
      ).map(UpcomingDebt.fromJson).toList(growable: false),
    );
  }

  final String month;
  final int netWorthMinor;
  final int monthlyIncomeMinor;
  final int monthlyExpenseMinor;
  final int monthlyCashflowMinor;
  final BudgetSummary budget;
  final List<UpcomingSubscription> upcomingSubscriptions;
  final List<UpcomingInstallment> upcomingInstallments;
  final List<UpcomingDebt> upcomingDebts;

  bool get hasUpcoming =>
      upcomingSubscriptions.isNotEmpty ||
      upcomingInstallments.isNotEmpty ||
      upcomingDebts.isNotEmpty;
}

class BudgetSummary {
  const BudgetSummary({
    required this.limitMinor,
    required this.spentMinor,
    required this.remainingMinor,
    required this.usagePercent,
  });

  factory BudgetSummary.fromJson(JsonMap json) {
    return BudgetSummary(
      limitMinor: ApiJson.readInt(json, 'limit_minor'),
      spentMinor: ApiJson.readInt(json, 'spent_minor'),
      remainingMinor: ApiJson.readInt(json, 'remaining_minor'),
      usagePercent: ApiJson.readDouble(json, 'usage_percent'),
    );
  }

  final int limitMinor;
  final int spentMinor;
  final int remainingMinor;
  final double usagePercent;
}

class UpcomingSubscription {
  const UpcomingSubscription({
    required this.id,
    required this.name,
    required this.accountDetail,
    required this.amountMinor,
    required this.nextDueDate,
  });

  factory UpcomingSubscription.fromJson(JsonMap json) {
    return UpcomingSubscription(
      id: ApiJson.readString(json, 'id'),
      name: ApiJson.readString(json, 'name'),
      accountDetail: ApiJson.optionalString(json, 'account_detail'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      nextDueDate: ApiJson.readString(json, 'next_due_date'),
    );
  }

  final String id;
  final String name;
  final String accountDetail;
  final int amountMinor;
  final String nextDueDate;
}

class UpcomingInstallment {
  const UpcomingInstallment({
    required this.id,
    required this.name,
    required this.monthlyAmountMinor,
    required this.remainingMonths,
    required this.dueDate,
  });

  factory UpcomingInstallment.fromJson(JsonMap json) {
    return UpcomingInstallment(
      id: ApiJson.readString(json, 'id'),
      name: ApiJson.readString(json, 'name'),
      monthlyAmountMinor: ApiJson.readInt(json, 'monthly_amount_minor'),
      remainingMonths: ApiJson.readInt(json, 'remaining_months'),
      dueDate: ApiJson.readString(json, 'due_date'),
    );
  }

  final String id;
  final String name;
  final int monthlyAmountMinor;
  final int remainingMonths;
  final String dueDate;
}

class UpcomingDebt {
  const UpcomingDebt({
    required this.id,
    required this.type,
    required this.counterpartyName,
    required this.remainingAmountMinor,
    required this.dueDate,
  });

  factory UpcomingDebt.fromJson(JsonMap json) {
    return UpcomingDebt(
      id: ApiJson.readString(json, 'id'),
      type: ApiJson.readString(json, 'type'),
      counterpartyName: ApiJson.readString(json, 'counterparty_name'),
      remainingAmountMinor: ApiJson.readInt(json, 'remaining_amount_minor'),
      dueDate: ApiJson.readString(json, 'due_date'),
    );
  }

  final String id;
  final String type;
  final String counterpartyName;
  final int remainingAmountMinor;
  final String dueDate;
}

class CashflowTrendPoint {
  const CashflowTrendPoint({
    required this.month,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.cashflowMinor,
  });

  factory CashflowTrendPoint.fromJson(JsonMap json) {
    return CashflowTrendPoint(
      month: ApiJson.readString(json, 'month'),
      incomeMinor: ApiJson.readInt(json, 'income_minor'),
      expenseMinor: ApiJson.readInt(json, 'expense_minor'),
      cashflowMinor: ApiJson.readInt(json, 'cashflow_minor'),
    );
  }

  final String month;
  final int incomeMinor;
  final int expenseMinor;
  final int cashflowMinor;
}

class CashflowTrendResponse {
  const CashflowTrendResponse({required this.trend});

  factory CashflowTrendResponse.fromJson(JsonMap json) {
    return CashflowTrendResponse(
      trend: ApiJson.readObjectList(
        json,
        'trend',
      ).map(CashflowTrendPoint.fromJson).toList(growable: false),
    );
  }

  final List<CashflowTrendPoint> trend;
}

class ExpenseDistribution {
  const ExpenseDistribution({
    required this.categoryId,
    required this.categoryName,
    required this.amountMinor,
    required this.percentage,
  });

  factory ExpenseDistribution.fromJson(JsonMap json) {
    return ExpenseDistribution(
      categoryId: ApiJson.readString(json, 'category_id'),
      categoryName: ApiJson.readString(json, 'category_name'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      percentage: ApiJson.readDouble(json, 'percentage'),
    );
  }

  final String categoryId;
  final String categoryName;
  final int amountMinor;
  final double percentage;
}

class ExpenseDistributionResponse {
  const ExpenseDistributionResponse({required this.distribution});

  factory ExpenseDistributionResponse.fromJson(JsonMap json) {
    return ExpenseDistributionResponse(
      distribution: ApiJson.readObjectList(
        json,
        'distribution',
      ).map(ExpenseDistribution.fromJson).toList(growable: false),
    );
  }

  final List<ExpenseDistribution> distribution;
}

enum ForecastStatus {
  safe,
  overbudget;

  static ForecastStatus fromApiValue(String value) {
    return switch (value) {
      'safe' => ForecastStatus.safe,
      'overbudget' => ForecastStatus.overbudget,
      _ => throw FormatException('Unknown forecast status "$value".'),
    };
  }
}

class DashboardForecast {
  const DashboardForecast({
    required this.currentExpenseMinor,
    required this.dailyAverageMinor,
    required this.forecastedExpenseMinor,
    required this.budgetLimitMinor,
    required this.status,
  });

  factory DashboardForecast.fromJson(JsonMap json) {
    return DashboardForecast(
      currentExpenseMinor: ApiJson.readInt(json, 'current_expense_minor'),
      dailyAverageMinor: ApiJson.readInt(json, 'daily_average_minor'),
      forecastedExpenseMinor: ApiJson.readInt(json, 'forecasted_expense_minor'),
      budgetLimitMinor: ApiJson.readInt(json, 'budget_limit_minor'),
      status: ForecastStatus.fromApiValue(ApiJson.readString(json, 'status')),
    );
  }

  final int currentExpenseMinor;
  final int dailyAverageMinor;
  final int forecastedExpenseMinor;
  final int budgetLimitMinor;
  final ForecastStatus status;
}
