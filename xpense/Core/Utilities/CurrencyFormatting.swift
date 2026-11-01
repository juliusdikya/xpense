import Foundation

/// Minimal IDR-first currency formatting/parsing. Assumes zero minor-unit
/// decimals (true for IDR); a currency with cents would need this extended.
enum CurrencyFormatting {
    static func format(minorUnits: Int64, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "id_ID")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(value: minorUnits)) ?? "\(minorUnits)"
    }

    /// Parses user input like "1.250.000" or "1250000" into minor units.
    static func parseMinorUnits(from text: String) -> Int64? {
        let digits = text.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return Int64(digits)
    }
}
