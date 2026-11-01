import Foundation
import SwiftData

enum WalletType: String, Codable, CaseIterable {
    case cash
    case bank
    case eWallet
    case other
}

/// A wallet's balance is never stored directly; it is derived as
/// `openingBalanceMinorUnits` plus every non-deleted `Transaction` that
/// references this wallet as source or destination. See `ReportingService`.
@Model
final class Wallet {
    var id: UUID
    var name: String
    var type: WalletType
    /// ISO 4217 currency code, e.g. "IDR".
    var currencyCode: String
    /// Smallest currency unit (e.g. Rupiah for IDR, cents for USD). Never `Double`.
    var openingBalanceMinorUnits: Int64
    var isArchived: Bool
    /// When true, excluded from the dashboard's total-balance sum.
    var excludeFromTotal: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        type: WalletType,
        currencyCode: String,
        openingBalanceMinorUnits: Int64 = 0,
        isArchived: Bool = false,
        excludeFromTotal: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.currencyCode = currencyCode
        self.openingBalanceMinorUnits = openingBalanceMinorUnits
        self.isArchived = isArchived
        self.excludeFromTotal = excludeFromTotal
        self.createdAt = createdAt
    }
}
