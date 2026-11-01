import Foundation

@Observable
@MainActor
final class WalletListViewModel {
    private(set) var wallets: [Wallet] = []
    private(set) var errorMessage: String?

    private let walletRepository: WalletRepository

    init(walletRepository: WalletRepository) {
        self.walletRepository = walletRepository
    }

    func load() {
        do {
            wallets = try walletRepository.fetchAll(includeArchived: false)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archive(_ wallet: Wallet) {
        do {
            try walletRepository.archive(wallet)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
