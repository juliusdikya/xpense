import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case custom
}

/// Generates due transactions on launch by copying `templateTransaction`'s
/// fields (type, amount, category, wallets, note) into a new real `Transaction`.
/// `templateTransaction.isRecurringTemplate` is always true and that row is
/// never itself counted in balances or reports.
@Model
final class RecurringSchedule {
    var id: UUID
    var frequency: RecurrenceFrequency
    /// Only used when `frequency == .custom`.
    var customIntervalDays: Int?
    var nextDueDate: Date
    var lastGeneratedDate: Date?
    var isActive: Bool
    /// When true, a generated transaction is held for user confirmation
    /// before being posted, instead of auto-posting.
    var requiresConfirmation: Bool

    @Relationship var templateTransaction: Transaction

    init(
        id: UUID = UUID(),
        frequency: RecurrenceFrequency,
        customIntervalDays: Int? = nil,
        nextDueDate: Date,
        lastGeneratedDate: Date? = nil,
        isActive: Bool = true,
        requiresConfirmation: Bool = true,
        templateTransaction: Transaction
    ) {
        self.id = id
        self.frequency = frequency
        self.customIntervalDays = customIntervalDays
        self.nextDueDate = nextDueDate
        self.lastGeneratedDate = lastGeneratedDate
        self.isActive = isActive
        self.requiresConfirmation = requiresConfirmation
        self.templateTransaction = templateTransaction
    }
}
