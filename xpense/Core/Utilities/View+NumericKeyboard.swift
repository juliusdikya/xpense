import SwiftUI

extension View {
    /// `.keyboardType(.numberPad)` is UIKit-only; this project's target also
    /// builds for macOS, which has no keyboard type concept.
    func numericKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }
}
