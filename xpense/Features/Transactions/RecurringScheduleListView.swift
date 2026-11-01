import SwiftUI

struct RecurringScheduleListView: View {
    @State private var viewModel: RecurringScheduleListViewModel
    @State private var showingForm = false
    private let transactionRepository: TransactionRepository
    private let scheduleRepository: RecurringScheduleRepository
    private let walletRepository: WalletRepository
    private let categoryRepository: CategoryRepository

    init(
        transactionRepository: TransactionRepository,
        scheduleRepository: RecurringScheduleRepository,
        walletRepository: WalletRepository,
        categoryRepository: CategoryRepository
    ) {
        self.transactionRepository = transactionRepository
        self.scheduleRepository = scheduleRepository
        self.walletRepository = walletRepository
        self.categoryRepository = categoryRepository
        _viewModel = State(initialValue: RecurringScheduleListViewModel(scheduleRepository: scheduleRepository))
    }

    var body: some View {
        Group {
            if viewModel.schedules.isEmpty {
                ContentUnavailableView("No recurring transactions", systemImage: "repeat")
            } else {
                List {
                    ForEach(viewModel.schedules, id: \.id) { schedule in
                        RecurringScheduleRow(schedule: schedule)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deactivate(viewModel.schedules[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Recurring")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") { showingForm = true }
            }
        }
        .sheet(isPresented: $showingForm, onDismiss: { viewModel.load() }) {
            RecurringScheduleFormView(
                transactionRepository: transactionRepository,
                scheduleRepository: scheduleRepository,
                walletRepository: walletRepository,
                categoryRepository: categoryRepository
            )
        }
        .onAppear { viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        RecurringScheduleListView(
            transactionRepository: MockTransactionRepository(),
            scheduleRepository: MockRecurringScheduleRepository(),
            walletRepository: MockWalletRepository(),
            categoryRepository: MockCategoryRepository()
        )
    }
}
