import Foundation
import SwiftData

/// Single composition root. Builds every repository once from one
/// `ModelContext` and exposes them as protocols. Features receive these
/// through their own ViewModel initializers — never via singletons or
/// implicit environment lookups.
@MainActor
final class DependencyContainer {
    let walletRepository: WalletRepository
    let categoryRepository: CategoryRepository
    let transactionRepository: TransactionRepository
    let budgetRepository: BudgetRepository
    let scheduleRepository: RecurringScheduleRepository
    let balanceCalculator: BalanceCalculating
    let reportingService: ReportingService
    let budgetProgressCalculator: BudgetProgressCalculating
    let recurringTransactionService: RecurringTransactionService
    let receiptOCRService: ReceiptOCRService
    let receiptParsingService: ReceiptParsingService
    let receiptValidationService: ReceiptValidationService
    let categorySeeder: CategorySeeding

    init(modelContext: ModelContext) {
        self.walletRepository = SwiftDataWalletRepository(modelContext: modelContext)
        self.categoryRepository = SwiftDataCategoryRepository(modelContext: modelContext)
        self.transactionRepository = SwiftDataTransactionRepository(modelContext: modelContext)
        self.budgetRepository = SwiftDataBudgetRepository(modelContext: modelContext)
        self.scheduleRepository = SwiftDataRecurringScheduleRepository(modelContext: modelContext)
        self.balanceCalculator = BalanceCalculator()
        self.reportingService = ReportingCalculator(balanceCalculator: self.balanceCalculator)
        self.budgetProgressCalculator = BudgetProgressCalculator()
        self.recurringTransactionService = DefaultRecurringTransactionService(
            transactionRepository: self.transactionRepository,
            scheduleRepository: self.scheduleRepository
        )
        self.receiptOCRService = VisionReceiptOCRService()
        self.receiptParsingService = FoundationModelsReceiptParsingService()
        self.receiptValidationService = DefaultReceiptValidationService()
        self.categorySeeder = DefaultCategorySeeder(categoryRepository: self.categoryRepository)
    }
}
