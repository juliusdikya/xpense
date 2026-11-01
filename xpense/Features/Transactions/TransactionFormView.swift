import SwiftUI

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TransactionFormViewModel

    init(transactionRepository: TransactionRepository, walletRepository: WalletRepository, categoryRepository: CategoryRepository) {
        let wallets = (try? walletRepository.fetchAll(includeArchived: false)) ?? []
        let categories = (try? categoryRepository.fetchAll(kind: nil, includeArchived: false)) ?? []
        _viewModel = State(initialValue: TransactionFormViewModel(
            transactionRepository: transactionRepository,
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
                    Text("Transfer").tag(TransactionType.transfer)
                }
                .pickerStyle(.segmented)

                TextField("Amount", text: $viewModel.amountText)
                    .numericKeyboard()

                Picker("Wallet", selection: $viewModel.sourceWalletID) {
                    ForEach(viewModel.wallets, id: \.id) { wallet in
                        Text(wallet.name).tag(Optional(wallet.id))
                    }
                }

                if viewModel.type == .transfer {
                    Picker("To wallet", selection: $viewModel.destinationWalletID) {
                        Text("Select").tag(UUID?.none)
                        ForEach(viewModel.wallets, id: \.id) { wallet in
                            Text(wallet.name).tag(Optional(wallet.id))
                        }
                    }
                    TextField("Fee (optional)", text: $viewModel.feeText)
                        .numericKeyboard()
                } else {
                    Picker("Category", selection: $viewModel.categoryID) {
                        Text("Select").tag(UUID?.none)
                        ForEach(viewModel.categoriesForSelectedType, id: \.id) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                }

                DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                TextField("Note", text: $viewModel.note)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("New Transaction")
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
    TransactionFormView(
        transactionRepository: MockTransactionRepository(),
        walletRepository: MockWalletRepository(),
        categoryRepository: MockCategoryRepository()
    )
}
