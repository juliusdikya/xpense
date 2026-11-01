import Foundation

/// `category == nil` matches an overall budget against every expense.
struct BudgetProgress {
    let budget: Budget
    let spentMinorUnits: Int64
    let percentUsed: Double

    var remainingMinorUnits: Int64 { budget.limitMinorUnits - spentMinorUnits }
    var isOverBudget: Bool { spentMinorUnits > budget.limitMinorUnits }
    var isWarning: Bool { percentUsed >= Double(budget.warnThresholdPercent) }
}

/// Pure math, no SwiftData.
protocol BudgetProgressCalculating {
    func progress(for budget: Budget, transactions: [Transaction], range: ClosedRange<Date>) -> BudgetProgress
}

struct BudgetProgressCalculator: BudgetProgressCalculating {
    func progress(for budget: Budget, transactions: [Transaction], range: ClosedRange<Date>) -> BudgetProgress {
        let spent = transactions
            .filter { !$0.isRecurringTemplate && $0.type == .expense && range.contains($0.date) }
            .filter { budget.category == nil || $0.category?.id == budget.category?.id }
            .reduce(Int64(0)) { $0 + $1.amountMinorUnits }

        let percent = budget.limitMinorUnits > 0
            ? (Double(spent) / Double(budget.limitMinorUnits)) * 100
            : 0

        return BudgetProgress(budget: budget, spentMinorUnits: spent, percentUsed: percent)
    }
}
