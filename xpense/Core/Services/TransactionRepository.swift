import Foundation
import SwiftData

struct TransactionFilter {
    var walletID: UUID?
    var categoryID: UUID?
    var types: Set<TransactionType>?
    var dateRange: ClosedRange<Date>?
    var searchText: String?
    var includeRecurringTemplates: Bool = false

    static let none = TransactionFilter()
}

protocol TransactionRepository {
    func fetchAll(filter: TransactionFilter) throws -> [Transaction]
    func fetch(id: UUID) throws -> Transaction?
    /// Transactions affecting the given wallet, as source or destination.
    func fetchAll(forWallet walletID: UUID) throws -> [Transaction]
    @discardableResult
    func create(_ transaction: Transaction) throws -> Transaction
    func update(_ transaction: Transaction) throws
    /// Deletion is real (unlike wallets/categories); callers capture a
    /// snapshot beforehand to support undo.
    func delete(_ transaction: Transaction) throws
}

@MainActor
final class SwiftDataTransactionRepository: TransactionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(filter: TransactionFilter) throws -> [Transaction] {
        var all = try modelContext.fetch(
            FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\Transaction.date, order: .reverse)])
        )

        if !filter.includeRecurringTemplates {
            all = all.filter { !$0.isRecurringTemplate }
        }
        if let walletID = filter.walletID {
            all = all.filter { $0.sourceWallet?.id == walletID || $0.destinationWallet?.id == walletID }
        }
        if let categoryID = filter.categoryID {
            all = all.filter { $0.category?.id == categoryID }
        }
        if let types = filter.types {
            all = all.filter { types.contains($0.type) }
        }
        if let dateRange = filter.dateRange {
            all = all.filter { dateRange.contains($0.date) }
        }
        if let searchText = filter.searchText, !searchText.isEmpty {
            let needle = searchText.lowercased()
            all = all.filter {
                $0.note.lowercased().contains(needle) || $0.category?.name.lowercased().contains(needle) == true
            }
        }
        return all
    }

    func fetch(id: UUID) throws -> Transaction? {
        let predicate = #Predicate<Transaction> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<Transaction>(predicate: predicate)).first
    }

    func fetchAll(forWallet walletID: UUID) throws -> [Transaction] {
        try fetchAll(filter: TransactionFilter(walletID: walletID))
    }

    @discardableResult
    func create(_ transaction: Transaction) throws -> Transaction {
        modelContext.insert(transaction)
        try save()
        return transaction
    }

    func update(_ transaction: Transaction) throws {
        try save()
    }

    func delete(_ transaction: Transaction) throws {
        modelContext.delete(transaction)
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
