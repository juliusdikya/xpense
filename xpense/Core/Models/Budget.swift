import Foundation
import SwiftData

enum BudgetPeriod: String, Codable, CaseIterable {
    case monthly
}

/// `category` nil means an overall budget across all categories.
/// Month boundaries follow the configurable "month starts on day N" setting,
/// not the calendar month. See `ReportingService`.
@Model
final class Budget {
    var id: UUID
    var period: BudgetPeriod
    var limitMinorUnits: Int64
    /// Percent (0-100) at which an in-app warning fires, e.g. 80.
    var warnThresholdPercent: Int
    var isArchived: Bool

    @Relationship var category: Category?

    init(
        id: UUID = UUID(),
        period: BudgetPeriod = .monthly,
        limitMinorUnits: Int64,
        warnThresholdPercent: Int = 80,
        isArchived: Bool = false,
        category: Category? = nil
    ) {
        self.id = id
        self.period = period
        self.limitMinorUnits = limitMinorUnits
        self.warnThresholdPercent = warnThresholdPercent
        self.isArchived = isArchived
        self.category = category
    }
}
