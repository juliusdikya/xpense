import Foundation
import SwiftData

enum CategoryKind: String, Codable, CaseIterable {
    case income
    case expense
}

/// Categories with transaction history are archived, never hard-deleted.
@Model
final class Category {
    var id: UUID
    var name: String
    var kind: CategoryKind
    /// Placeholder symbol name; real iconography is a POC-UI concern.
    var iconName: String
    var isArchived: Bool
    var isDefault: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        kind: CategoryKind,
        iconName: String = "tag",
        isArchived: Bool = false,
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.iconName = iconName
        self.isArchived = isArchived
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
}
