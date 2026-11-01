import Foundation

/// Covers income/expense/transfer entry. `adjustment` transactions are
/// created only through the wallet balance-correction flow, not this form.
@Observable
@MainActor
final class TransactionFormViewModel {
    var type: TransactionType = .expense
    var amountText: String = ""
    var feeText: String = ""
    var date: Date = .now
    var note: String = ""
    var sourceWalletID: UUID?
    var destinationWalletID: UUID?
    var categoryID: UUID?
    private(set) var errorMessage: String?

    let wallets: [Wallet]
    let categories: [Category]

    private let transactionRepository: TransactionRepository

    init(transactionRepository: TransactionRepository, wallets: [Wallet], categories: [Category]) {
        self.transactionRepository = transactionRepository
        self.wallets = wallets
        self.categories = categories
        self.sourceWalletID = wallets.first?.id
    }

    var categoriesForSelectedType: [Category] {
        guard type != .transfer else { return [] }
        let kind: CategoryKind = type == .income ? .income : .expense
        return categories.filter { $0.kind == kind }
    }

    @discardableResult
    func save() -> Bool {
        guard let amount = CurrencyFormatting.parseMinorUnits(from: amountText), amount > 0 else {
            errorMessage = "Enter an amount greater than zero."
            return false
        }
        guard let sourceWalletID, let sourceWallet = wallets.first(where: { $0.id == sourceWalletID }) else {
            errorMessage = "Select a wallet."
            return false
        }

        var destinationWallet: Wallet?
        var fee: Int64 = 0
        if type == .transfer {
            guard let destinationWalletID, let destination = wallets.first(where: { $0.id == destinationWalletID }) else {
                errorMessage = "Select a destination wallet."
                return false
            }
            guard destination.id != sourceWallet.id else {
                errorMessage = "Source and destination wallets must differ."
                return false
            }
            destinationWallet = destination
            fee = CurrencyFormatting.parseMinorUnits(from: feeText) ?? 0
        }

        var category: Category?
        if type != .transfer {
            guard let categoryID, let selected = categories.first(where: { $0.id == categoryID }) else {
                errorMessage = "Select a category."
                return false
            }
            category = selected
        }

        let transaction = Transaction(
            type: type,
            amountMinorUnits: amount,
            feeMinorUnits: fee,
            date: date,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceWallet: sourceWallet,
            destinationWallet: destinationWallet,
            category: category
        )

        do {
            try transactionRepository.create(transaction)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
