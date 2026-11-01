import SwiftUI

struct WalletFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WalletFormViewModel

    init(walletRepository: WalletRepository) {
        _viewModel = State(initialValue: WalletFormViewModel(walletRepository: walletRepository))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $viewModel.name)
                Picker("Type", selection: $viewModel.type) {
                    ForEach(WalletType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                TextField("Opening balance", text: $viewModel.openingBalanceText)
                    .numericKeyboard()
                Toggle("Exclude from total", isOn: $viewModel.excludeFromTotal)
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("New Wallet")
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
    WalletFormView(walletRepository: MockWalletRepository())
}
