import Foundation

/// In-memory mock for previews and tests. No SwiftData involved.
final class MockWalletRepository: WalletRepository {
    private(set) var wallets: [Wallet]

    init(wallets: [Wallet] = MockWalletRepository.sampleWallets) {
        self.wallets = wallets
    }

    func fetchAll(includeArchived: Bool) throws -> [Wallet] {
        includeArchived ? wallets : wallets.filter { !$0.isArchived }
    }

    func fetch(id: UUID) throws -> Wallet? {
        wallets.first { $0.id == id }
    }

    @discardableResult
    func create(
        name: String,
        type: WalletType,
        currencyCode: String,
        openingBalanceMinorUnits: Int64,
        excludeFromTotal: Bool
    ) throws -> Wallet {
        let wallet = Wallet(
            name: name,
            type: type,
            currencyCode: currencyCode,
            openingBalanceMinorUnits: openingBalanceMinorUnits,
            excludeFromTotal: excludeFromTotal
        )
        wallets.append(wallet)
        return wallet
    }

    func update(_ wallet: Wallet) throws {}

    func archive(_ wallet: Wallet) throws {
        wallet.isArchived = true
    }

    static var sampleWallets: [Wallet] {
        [
            Wallet(name: "Cash", type: .cash, currencyCode: "IDR", openingBalanceMinorUnits: 500_000),
            Wallet(name: "BCA", type: .bank, currencyCode: "IDR", openingBalanceMinorUnits: 3_250_000),
            Wallet(name: "GoPay", type: .eWallet, currencyCode: "IDR", openingBalanceMinorUnits: 150_000),
        ]
    }
}
