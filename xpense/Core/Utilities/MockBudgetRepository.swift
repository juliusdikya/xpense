import Foundation

/// In-memory mock for previews and tests. No SwiftData involved.
final class MockBudgetRepository: BudgetRepository {
    private(set) var budgets: [Budget]

    init(budgets: [Budget] = []) {
        self.budgets = budgets
    }

    func fetchAll(includeArchived: Bool) throws -> [Budget] {
        includeArchived ? budgets : budgets.filter { !$0.isArchived }
    }

    func fetch(id: UUID) throws -> Budget? {
        budgets.first { $0.id == id }
    }

    @discardableResult
    func create(
        period: BudgetPeriod,
        limitMinorUnits: Int64,
        warnThresholdPercent: Int,
        category: Category?
    ) throws -> Budget {
        let budget = Budget(
            period: period,
            limitMinorUnits: limitMinorUnits,
            warnThresholdPercent: warnThresholdPercent,
            category: category
        )
        budgets.append(budget)
        return budget
    }

    func update(_ budget: Budget) throws {}

    func archive(_ budget: Budget) throws {
        budget.isArchived = true
    }
}
