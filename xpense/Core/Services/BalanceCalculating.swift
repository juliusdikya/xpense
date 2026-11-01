import Foundation

/// Pure balance math, no SwiftData. Balance is never a stored value; it is
/// always opening balance plus every transaction touching the wallet.
protocol BalanceCalculating {
    func balance(wallet: Wallet, transactions: [Transaction]) -> Int64
}

struct BalanceCalculator: BalanceCalculating {
    func balance(wallet: Wallet, transactions: [Transaction]) -> Int64 {
        var total = wallet.openingBalanceMinorUnits
        for transaction in transactions where !transaction.isRecurringTemplate {
            switch transaction.type {
            case .income:
                if transaction.sourceWallet?.id == wallet.id {
                    total += transaction.amountMinorUnits
                }
            case .expense:
                if transaction.sourceWallet?.id == wallet.id {
                    total -= transaction.amountMinorUnits
                }
            case .transfer:
                if transaction.sourceWallet?.id == wallet.id {
                    total -= transaction.amountMinorUnits + transaction.feeMinorUnits
                }
                if transaction.destinationWallet?.id == wallet.id {
                    total += transaction.amountMinorUnits
                }
            case .adjustment:
                if transaction.sourceWallet?.id == wallet.id {
                    total += transaction.amountMinorUnits
                }
            }
        }
        return total
    }
}
