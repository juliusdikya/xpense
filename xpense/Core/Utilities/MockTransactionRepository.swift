import Foundation

/// In-memory mock for previews and tests. No SwiftData involved.
final class MockTransactionRepository: TransactionRepository {
    private(set) var transactions: [Transaction]

    init(transactions: [Transaction] = []) {
        self.transactions = transactions
    }

    func fetchAll(filter: TransactionFilter) throws -> [Transaction] {
        transactions
            .filter { filter.includeRecurringTemplates || !$0.isRecurringTemplate }
            .sorted { $0.date > $1.date }
    }

    func fetch(id: UUID) throws -> Transaction? {
        transactions.first { $0.id == id }
    }

    func fetchAll(forWallet walletID: UUID) throws -> [Transaction] {
        transactions.filter { $0.sourceWallet?.id == walletID || $0.destinationWallet?.id == walletID }
    }

    @discardableResult
    func create(_ transaction: Transaction) throws -> Transaction {
        transactions.append(transaction)
        return transaction
    }

    func update(_ transaction: Transaction) throws {}

    func delete(_ transaction: Transaction) throws {
        transactions.removeAll { $0.id == transaction.id }
    }
}
