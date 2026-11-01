import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense
    case transfer
    /// Explicit, auditable wallet balance correction. Never a silent overwrite.
    case adjustment
}

/// A transfer is ONE record (`sourceWallet` + `destinationWallet`), never two
/// income/expense rows, and is excluded from income/expense totals in
/// `ReportingService`. An `adjustment` uses only `sourceWallet`.
///
/// `isRecurringTemplate` marks a draft row that is never itself included in
/// balances or reports; it exists only to be copied by `RecurringTransactionService`
/// when `RecurringSchedule` generates a due transaction.
@Model
final class Transaction {
    var id: UUID
    var type: TransactionType
    /// Smallest currency unit. Never `Double`.
    var amountMinorUnits: Int64
    /// Transfer-only fee, smallest currency unit. Zero otherwise.
    var feeMinorUnits: Int64
    var date: Date
    var note: String
    var tags: [String]
    var needsReview: Bool
    var receiptImagePath: String?
    var isRecurringTemplate: Bool
    var createdAt: Date

    @Relationship var sourceWallet: Wallet?
    @Relationship var destinationWallet: Wallet?
    @Relationship var category: Category?

    init(
        id: UUID = UUID(),
        type: TransactionType,
        amountMinorUnits: Int64,
        feeMinorUnits: Int64 = 0,
        date: Date = .now,
        note: String = "",
        tags: [String] = [],
        needsReview: Bool = false,
        receiptImagePath: String? = nil,
        isRecurringTemplate: Bool = false,
        sourceWallet: Wallet? = nil,
        destinationWallet: Wallet? = nil,
        category: Category? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.amountMinorUnits = amountMinorUnits
        self.feeMinorUnits = feeMinorUnits
        self.date = date
        self.note = note
        self.tags = tags
        self.needsReview = needsReview
        self.receiptImagePath = receiptImagePath
        self.isRecurringTemplate = isRecurringTemplate
        self.sourceWallet = sourceWallet
        self.destinationWallet = destinationWallet
        self.category = category
        self.createdAt = createdAt
    }
}
