import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    private(set) var totalBalanceMinorUnits: Int64 = 0
    private(set) var summary = MonthlySummary(totalIncomeMinorUnits: 0, totalExpenseMinorUnits: 0)
    private(set) var recentTransactions: [Transaction] = []
    private(set) var errorMessage: String?

    private let walletRepository: WalletRepository
    private let transactionRepository: TransactionRepository
    private let reportingService: ReportingService
    /// Hardcoded until the Settings feature exposes it. Valid range 1-28.
    private let monthStartDay: Int

    init(
        walletRepository: WalletRepository,
        transactionRepository: TransactionRepository,
        reportingService: ReportingService,
        monthStartDay: Int = 1
    ) {
        self.walletRepository = walletRepository
        self.transactionRepository = transactionRepository
        self.reportingService = reportingService
        self.monthStartDay = monthStartDay
    }

    func load() {
        do {
            let wallets = try walletRepository.fetchAll(includeArchived: false)
            let transactions = try transactionRepository.fetchAll(filter: .none)
            totalBalanceMinorUnits = reportingService.totalBalance(wallets: wallets, transactions: transactions)
            let range = reportingService.monthRange(containing: .now, monthStartDay: monthStartDay)
            summary = reportingService.monthlySummary(transactions: transactions, range: range)
            recentTransactions = Array(transactions.prefix(5))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
