import SwiftData
import SwiftUI

@main struct MyApp: App {
    private let modelContainer: ModelContainer
    private let dependencyContainer: DependencyContainer
    private let initialPendingRecurring: [PendingRecurringTransaction]
    @State private var showingPendingRecurring: Bool

    init() {
        let schema = Schema([
            Wallet.self,
            Category.self,
            Transaction.self,
            Budget.self,
            RecurringSchedule.self,
        ])
        do {
            modelContainer = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        dependencyContainer = DependencyContainer(modelContext: modelContainer.mainContext)
        do {
            try dependencyContainer.categorySeeder.seedDefaultsIfNeeded()
        } catch {
            print("Failed to seed default categories: \(error)")
        }

        do {
            initialPendingRecurring = try dependencyContainer.recurringTransactionService.generateDueTransactions(asOf: .now)
        } catch {
            print("Failed to generate due recurring transactions: \(error)")
            initialPendingRecurring = []
        }
        _showingPendingRecurring = State(initialValue: !initialPendingRecurring.isEmpty)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView(
                    walletRepository: dependencyContainer.walletRepository,
                    transactionRepository: dependencyContainer.transactionRepository,
                    reportingService: dependencyContainer.reportingService
                )
                .tabItem { Label("Dashboard", systemImage: "house") }
                WalletListView(walletRepository: dependencyContainer.walletRepository)
                    .tabItem { Label("Wallets", systemImage: "wallet.pass") }
                TransactionListView(
                    transactionRepository: dependencyContainer.transactionRepository,
                    walletRepository: dependencyContainer.walletRepository,
                    categoryRepository: dependencyContainer.categoryRepository,
                    scheduleRepository: dependencyContainer.scheduleRepository
                )
                .tabItem { Label("Transactions", systemImage: "list.bullet") }
                BudgetListView(
                    budgetRepository: dependencyContainer.budgetRepository,
                    transactionRepository: dependencyContainer.transactionRepository,
                    reportingService: dependencyContainer.reportingService,
                    budgetProgressCalculator: dependencyContainer.budgetProgressCalculator,
                    categoryRepository: dependencyContainer.categoryRepository
                )
                .tabItem { Label("Budgets", systemImage: "chart.pie") }
                ReceiptImportView(
                    walletRepository: dependencyContainer.walletRepository,
                    categoryRepository: dependencyContainer.categoryRepository,
                    ocrService: dependencyContainer.receiptOCRService,
                    parsingService: dependencyContainer.receiptParsingService,
                    validationService: dependencyContainer.receiptValidationService,
                    transactionRepository: dependencyContainer.transactionRepository
                )
                .tabItem { Label("Import", systemImage: "camera.viewfinder") }
            }
            .sheet(isPresented: $showingPendingRecurring) {
                RecurringPendingView(
                    initialQueue: initialPendingRecurring,
                    service: dependencyContainer.recurringTransactionService,
                    onFinished: { showingPendingRecurring = false }
                )
            }
        }
        .modelContainer(modelContainer)
    }
}
