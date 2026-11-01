import SwiftUI

struct TransactionListView: View {
    @State private var viewModel: TransactionListViewModel
    @State private var showingForm = false
    private let transactionRepository: TransactionRepository
    private let walletRepository: WalletRepository
    private let categoryRepository: CategoryRepository
    private let scheduleRepository: RecurringScheduleRepository

    init(
        transactionRepository: TransactionRepository,
        walletRepository: WalletRepository,
        categoryRepository: CategoryRepository,
        scheduleRepository: RecurringScheduleRepository
    ) {
        self.transactionRepository = transactionRepository
        self.walletRepository = walletRepository
        self.categoryRepository = categoryRepository
        self.scheduleRepository = scheduleRepository
        _viewModel = State(initialValue: TransactionListViewModel(transactionRepository: transactionRepository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.transactions.isEmpty {
                    ContentUnavailableView("No transactions yet", systemImage: "list.bullet")
                } else {
                    List {
                        ForEach(viewModel.transactions, id: \.id) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.delete(viewModel.transactions[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("Recurring") {
                        RecurringScheduleListView(
                            transactionRepository: transactionRepository,
                            scheduleRepository: scheduleRepository,
                            walletRepository: walletRepository,
                            categoryRepository: categoryRepository
                        )
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") { showingForm = true }
                }
            }
            .sheet(isPresented: $showingForm, onDismiss: { viewModel.load() }) {
                TransactionFormView(
                    transactionRepository: transactionRepository,
                    walletRepository: walletRepository,
                    categoryRepository: categoryRepository
                )
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.lastDeletedSnapshot != nil {
                    HStack {
                        Text("Transaction deleted")
                        Spacer()
                        Button("Undo") { viewModel.undoDelete() }
                    }
                    .padding()
                    .background(.bar)
                }
            }
            .onAppear { viewModel.load() }
        }
    }
}

#Preview {
    TransactionListView(
        transactionRepository: MockTransactionRepository(),
        walletRepository: MockWalletRepository(),
        categoryRepository: MockCategoryRepository(),
        scheduleRepository: MockRecurringScheduleRepository()
    )
}
