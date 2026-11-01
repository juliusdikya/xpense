import Foundation

@Observable
@MainActor
final class BudgetFormViewModel {
    var limitText: String = ""
    var warnThresholdPercent: Int = 80
    /// nil = overall budget across all expense categories.
    var categoryID: UUID?
    private(set) var errorMessage: String?

    let expenseCategories: [Category]

    private let budgetRepository: BudgetRepository

    init(budgetRepository: BudgetRepository, categories: [Category]) {
        self.budgetRepository = budgetRepository
        self.expenseCategories = categories.filter { $0.kind == .expense }
    }

    @discardableResult
    func save() -> Bool {
        guard let limit = CurrencyFormatting.parseMinorUnits(from: limitText), limit > 0 else {
            errorMessage = "Enter a limit greater than zero."
            return false
        }
        let category = expenseCategories.first { $0.id == categoryID }
        do {
            try budgetRepository.create(
                period: .monthly,
                limitMinorUnits: limit,
                warnThresholdPercent: warnThresholdPercent,
                category: category
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
