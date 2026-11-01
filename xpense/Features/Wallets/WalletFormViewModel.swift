import Foundation

@Observable
@MainActor
final class WalletFormViewModel {
    var name: String = ""
    var type: WalletType = .cash
    var currencyCode: String = "IDR"
    var openingBalanceText: String = ""
    var excludeFromTotal: Bool = false
    private(set) var errorMessage: String?

    private let walletRepository: WalletRepository

    init(walletRepository: WalletRepository) {
        self.walletRepository = walletRepository
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @discardableResult
    func save() -> Bool {
        guard canSave else {
            errorMessage = "Wallet name is required."
            return false
        }
        let openingBalance = CurrencyFormatting.parseMinorUnits(from: openingBalanceText) ?? 0
        do {
            try walletRepository.create(
                name: name.trimmingCharacters(in: .whitespaces),
                type: type,
                currencyCode: currencyCode,
                openingBalanceMinorUnits: openingBalance,
                excludeFromTotal: excludeFromTotal
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
