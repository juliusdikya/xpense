import SwiftUI

struct BudgetListView: View {
    @State private var viewModel: BudgetListViewModel
    @State private var showingForm = false
    private let budgetRepository: BudgetRepository
    private let categoryRepository: CategoryRepository

    init(
        budgetRepository: BudgetRepository,
        transactionRepository: TransactionRepository,
        reportingService: ReportingService,
        budgetProgressCalculator: BudgetProgressCalculating,
        categoryRepository: CategoryRepository
    ) {
        self.budgetRepository = budgetRepository
        self.categoryRepository = categoryRepository
        _viewModel = State(initialValue: BudgetListViewModel(
            budgetRepository: budgetRepository,
            transactionRepository: transactionRepository,
            reportingService: reportingService,
            progressCalculator: budgetProgressCalculator
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.progresses.isEmpty {
                    ContentUnavailableView("No budgets yet", systemImage: "chart.pie")
                } else {
                    List {
                        ForEach(viewModel.progresses, id: \.budget.id) { progress in
                            BudgetRow(progress: progress)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.archive(viewModel.progresses[index].budget)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") { showingForm = true }
                }
            }
            .sheet(isPresented: $showingForm, onDismiss: { viewModel.load() }) {
                BudgetFormView(budgetRepository: budgetRepository, categoryRepository: categoryRepository)
            }
            .onAppear { viewModel.load() }
        }
    }
}

#Preview {
    BudgetListView(
        budgetRepository: MockBudgetRepository(),
        transactionRepository: MockTransactionRepository(),
        reportingService: ReportingCalculator(),
        budgetProgressCalculator: BudgetProgressCalculator(),
        categoryRepository: MockCategoryRepository()
    )
}
