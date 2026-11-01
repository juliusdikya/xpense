import SwiftUI

struct WalletListView: View {
    @State private var viewModel: WalletListViewModel
    @State private var showingForm = false
    private let walletRepository: WalletRepository

    init(walletRepository: WalletRepository) {
        self.walletRepository = walletRepository
        _viewModel = State(initialValue: WalletListViewModel(walletRepository: walletRepository))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.wallets.isEmpty {
                    ContentUnavailableView("No wallets yet", systemImage: "wallet.pass")
                } else {
                    List {
                        ForEach(viewModel.wallets, id: \.id) { wallet in
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text(wallet.name)
                                Text(CurrencyFormatting.format(
                                    minorUnits: wallet.openingBalanceMinorUnits,
                                    currencyCode: wallet.currencyCode
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.archive(viewModel.wallets[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wallets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") { showingForm = true }
                }
            }
            .sheet(isPresented: $showingForm, onDismiss: { viewModel.load() }) {
                WalletFormView(walletRepository: walletRepository)
            }
            .onAppear { viewModel.load() }
        }
    }
}

#Preview {
    WalletListView(walletRepository: MockWalletRepository())
}
