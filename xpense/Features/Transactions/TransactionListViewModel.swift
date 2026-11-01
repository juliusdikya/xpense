import Foundation

/// Plain-value capture of a deleted transaction's fields, used to support
/// undo without relying on a dangling SwiftData model reference.
struct DeletedTransactionSnapshot {
    let type: TransactionType
    let amountMinorUnits: Int64
    let feeMinorUnits: Int64
    let date: Date
    let note: String
    let tags: [String]
    let sourceWallet: Wallet?
    let destinationWallet: Wallet?
    let category: Category?

    init(transaction: Transaction) {
        type = transaction.type
        amountMinorUnits = transaction.amountMinorUnits
        feeMinorUnits = transaction.feeMinorUnits
        date = transaction.date
        note = transaction.note
        tags = transaction.tags
        sourceWallet = transaction.sourceWallet
        destinationWallet = transaction.destinationWallet
        category = transaction.category
    }

    func makeTransaction() -> Transaction {
        Transaction(
            type: type,
            amountMinorUnits: amountMinorUnits,
            feeMinorUnits: feeMinorUnits,
            date: date,
            note: note,
            tags: tags,
            sourceWallet: sourceWallet,
            destinationWallet: destinationWallet,
            category: category
        )
    }
}

@Observable
@MainActor
final class TransactionListViewModel {
    private(set) var transactions: [Transaction] = []
    private(set) var errorMessage: String?
    private(set) var lastDeletedSnapshot: DeletedTransactionSnapshot?

    private let transactionRepository: TransactionRepository

    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func load() {
        do {
            transactions = try transactionRepository.fetchAll(filter: .none)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ transaction: Transaction) {
        lastDeletedSnapshot = DeletedTransactionSnapshot(transaction: transaction)
        do {
            try transactionRepository.delete(transaction)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoDelete() {
        guard let snapshot = lastDeletedSnapshot else { return }
        do {
            try transactionRepository.create(snapshot.makeTransaction())
            lastDeletedSnapshot = nil
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissUndo() {
        lastDeletedSnapshot = nil
    }
}
