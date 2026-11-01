import Foundation
import SwiftData

protocol BudgetRepository {
    func fetchAll(includeArchived: Bool) throws -> [Budget]
    func fetch(id: UUID) throws -> Budget?
    @discardableResult
    func create(
        period: BudgetPeriod,
        limitMinorUnits: Int64,
        warnThresholdPercent: Int,
        category: Category?
    ) throws -> Budget
    func update(_ budget: Budget) throws
    func archive(_ budget: Budget) throws
}

@MainActor
final class SwiftDataBudgetRepository: BudgetRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(includeArchived: Bool) throws -> [Budget] {
        if includeArchived {
            return try modelContext.fetch(FetchDescriptor<Budget>())
        }
        let predicate = #Predicate<Budget> { !$0.isArchived }
        return try modelContext.fetch(FetchDescriptor<Budget>(predicate: predicate))
    }

    func fetch(id: UUID) throws -> Budget? {
        let predicate = #Predicate<Budget> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<Budget>(predicate: predicate)).first
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
        modelContext.insert(budget)
        try save()
        return budget
    }

    func update(_ budget: Budget) throws {
        try save()
    }

    func archive(_ budget: Budget) throws {
        budget.isArchived = true
        try save()
    }

    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed(underlying: error)
        }
    }
}
