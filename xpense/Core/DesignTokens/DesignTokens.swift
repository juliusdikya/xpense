import SwiftUI

/// Single source of truth for visual constants. Views must read spacing,
/// colors, and type from here rather than hardcoding values, so the POC UI
/// can be replaced later without touching ViewModels or Services.
enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
    }
}
