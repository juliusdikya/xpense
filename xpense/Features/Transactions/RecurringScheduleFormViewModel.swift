import Foundation

/// Covers income/expense only. Transfers aren't supported as recurring
/// templates in this POC — bills/salary/subscriptions are the target use case.
@Observable
@MainActor
final class RecurringScheduleFormViewModel {
    var type: TransactionType = .expense
    var amountText: String = ""
    var note: String = ""
    var sourceWalletID: UUID?
    var categoryID: UUID?
    var frequency: RecurrenceFrequency = .monthly
    var customIntervalDaysText: String = "30"
    var startDate: Date = .now
    var requiresConfirmation: Bool = true
    private(set) var errorMessage: String?

    let wallets: [Wallet]
    let categories: [Category]

    private let transactionRepository: TransactionRepository
    private let scheduleRepository: RecurringScheduleRepository

    init(
        transactionRepository: TransactionRepository,
        scheduleRepository: RecurringScheduleRepository,
        wallets: [Wallet],
        categories: [Category]
    ) {
        self.transactionRepository = transactionRepository
        self.scheduleRepository = scheduleRepository
        self.wallets = wallets
        self.categories = categories
        self.sourceWalletID = wallets.first?.id
    }

    var categoriesForSelectedType: [Category] {
        let kind: CategoryKind = type == .income ? .income : .expense
        return categories.filter { $0.kind == kind }
    }

    @discardableResult
    func save() -> Bool {
        guard let amount = CurrencyFormatting.parseMinorUnits(from: amountText), amount > 0 else {
            errorMessage = "Enter an amount greater than zero."
            return false
        }
        guard let sourceWalletID, let wallet = wallets.first(where: { $0.id == sourceWalletID }) else {
            errorMessage = "Select a wallet."
            return false
        }
        guard let categoryID, let category = categories.first(where: { $0.id == categoryID }) else {
            errorMessage = "Select a category."
            return false
        }

        var customIntervalDays: Int?
        if frequency == .custom {
            guard let days = Int(customIntervalDaysText), days > 0 else {
                errorMessage = "Enter a custom interval in days."
                return false
            }
            customIntervalDays = days
        }

        do {
            let template = try transactionRepository.create(
                Transaction(
                    type: type,
                    amountMinorUnits: amount,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                    isRecurringTemplate: true,
                    sourceWallet: wallet,
                    category: category
                )
            )
            try scheduleRepository.create(
                templateTransaction: template,
                frequency: frequency,
                customIntervalDays: customIntervalDays,
                nextDueDate: startDate,
                requiresConfirmation: requiresConfirmation
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
