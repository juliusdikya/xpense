import SwiftUI

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: BudgetFormViewModel

    init(budgetRepository: BudgetRepository, categoryRepository: CategoryRepository) {
        let categories = (try? categoryRepository.fetchAll(kind: .expense, includeArchived: false)) ?? []
        _viewModel = State(initialValue: BudgetFormViewModel(budgetRepository: budgetRepository, categories: categories))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Monthly limit", text: $viewModel.limitText)
                    .numericKeyboard()

                Picker("Category", selection: $viewModel.categoryID) {
                    Text("Overall").tag(UUID?.none)
                    ForEach(viewModel.expenseCategories, id: \.id) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }

                Stepper("Warn at \(viewModel.warnThresholdPercent)%", value: $viewModel.warnThresholdPercent, in: 10...100, step: 5)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("New Budget")
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
    BudgetFormView(budgetRepository: MockBudgetRepository(), categoryRepository: MockCategoryRepository())
}
