import Foundation

@Observable
@MainActor
final class BudgetListViewModel {
    private(set) var progresses: [BudgetProgress] = []
    private(set) var errorMessage: String?

    private let budgetRepository: BudgetRepository
    private let transactionRepository: TransactionRepository
    private let reportingService: ReportingService
    private let progressCalculator: BudgetProgressCalculating
    /// Hardcoded until the Settings feature exposes it. Valid range 1-28.
    private let monthStartDay: Int

    init(
        budgetRepository: BudgetRepository,
        transactionRepository: TransactionRepository,
        reportingService: ReportingService,
        progressCalculator: BudgetProgressCalculating = BudgetProgressCalculator(),
        monthStartDay: Int = 1
    ) {
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
        self.reportingService = reportingService
        self.progressCalculator = progressCalculator
        self.monthStartDay = monthStartDay
    }

    func load() {
        do {
            let budgets = try budgetRepository.fetchAll(includeArchived: false)
            let transactions = try transactionRepository.fetchAll(filter: .none)
            let range = reportingService.monthRange(containing: .now, monthStartDay: monthStartDay)
            progresses = budgets.map { progressCalculator.progress(for: $0, transactions: transactions, range: range) }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archive(_ budget: Budget) {
        do {
            try budgetRepository.archive(budget)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
