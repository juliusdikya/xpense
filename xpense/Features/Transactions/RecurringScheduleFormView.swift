import SwiftUI

struct RecurringScheduleFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecurringScheduleFormViewModel

    init(
        transactionRepository: TransactionRepository,
        scheduleRepository: RecurringScheduleRepository,
        walletRepository: WalletRepository,
        categoryRepository: CategoryRepository
    ) {
        let wallets = (try? walletRepository.fetchAll(includeArchived: false)) ?? []
        let categories = (try? categoryRepository.fetchAll(kind: nil, includeArchived: false)) ?? []
        _viewModel = State(initialValue: RecurringScheduleFormViewModel(
            transactionRepository: transactionRepository,
            scheduleRepository: scheduleRepository,
            wallets: wallets,
            categories: categories
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $viewModel.type) {
                    Text("Expense").tag(TransactionType.expense)
                    Text("Income").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)

                TextField("Amount", text: $viewModel.amountText)
                    .numericKeyboard()

                Picker("Wallet", selection: $viewModel.sourceWalletID) {
                    ForEach(viewModel.wallets, id: \.id) { wallet in
                        Text(wallet.name).tag(Optional(wallet.id))
                    }
                }

                Picker("Category", selection: $viewModel.categoryID) {
                    Text("Select").tag(UUID?.none)
                    ForEach(viewModel.categoriesForSelectedType, id: \.id) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }

                TextField("Note", text: $viewModel.note)

                Picker("Frequency", selection: $viewModel.frequency) {
                    Text("Daily").tag(RecurrenceFrequency.daily)
                    Text("Weekly").tag(RecurrenceFrequency.weekly)
                    Text("Monthly").tag(RecurrenceFrequency.monthly)
                    Text("Custom").tag(RecurrenceFrequency.custom)
                }

                if viewModel.frequency == .custom {
                    TextField("Every N days", text: $viewModel.customIntervalDaysText)
                        .numericKeyboard()
                }

                DatePicker("Starts", selection: $viewModel.startDate, displayedComponents: .date)
                Toggle("Confirm before posting", isOn: $viewModel.requiresConfirmation)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("New Recurring")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save() { dismiss() }
                    }
                }
            }
        }
    }
}

#Preview {
    RecurringScheduleFormView(
        transactionRepository: MockTransactionRepository(),
        scheduleRepository: MockRecurringScheduleRepository(),
        walletRepository: MockWalletRepository(),
        categoryRepository: MockCategoryRepository()
    )
}
