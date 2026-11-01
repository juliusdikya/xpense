import Foundation
import SwiftData

protocol WalletRepository {
    func fetchAll(includeArchived: Bool) throws -> [Wallet]
    func fetch(id: UUID) throws -> Wallet?
    @discardableResult
    func create(
        name: String,
        type: WalletType,
        currencyCode: String,
        openingBalanceMinorUnits: Int64,
        excludeFromTotal: Bool
    ) throws -> Wallet
    func update(_ wallet: Wallet) throws
    /// Wallets with history are archived, never hard-deleted.
    func archive(_ wallet: Wallet) throws
}

@MainActor
final class SwiftDataWalletRepository: WalletRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(includeArchived: Bool) throws -> [Wallet] {
        let sort = [SortDescriptor(\Wallet.createdAt)]
        if includeArchived {
            return try modelContext.fetch(FetchDescriptor<Wallet>(sortBy: sort))
        }
        let predicate = #Predicate<Wallet> { !$0.isArchived }
        return try modelContext.fetch(FetchDescriptor<Wallet>(predicate: predicate, sortBy: sort))
    }

    func fetch(id: UUID) throws -> Wallet? {
        let predicate = #Predicate<Wallet> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<Wallet>(predicate: predicate)).first
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
        modelContext.insert(wallet)
        try save()
        return wallet
    }

    func update(_ wallet: Wallet) throws {
        try save()
    }

    func archive(_ wallet: Wallet) throws {
        wallet.isArchived = true
        try save()
    }

    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed(underlying: error)
        }
    }
}
