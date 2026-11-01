import Foundation

/// Deterministic re-check of model output. The model's `ParsedReceipt` is
/// never trusted directly — `amountMinorUnits`/`date` here are what the
/// review screen and save flow actually use.
struct ReceiptValidationResult {
    let amountMinorUnits: Int64?
    let date: Date?
    let errors: [String]
    let possibleDuplicate: Transaction?

    var isValid: Bool { errors.isEmpty && amountMinorUnits != nil && date != nil }
}

protocol ReceiptValidationService {
    func validate(_ receipt: ParsedReceipt, existingTransactions: [Transaction], now: Date) -> ReceiptValidationResult
}

struct DefaultReceiptValidationService: ReceiptValidationService {
    private let dateFormatters: [DateFormatter]

    init() {
        let patterns = ["dd/MM/yyyy", "d/M/yyyy", "yyyy-MM-dd", "dd-MM-yyyy", "d MMMM yyyy"]
        dateFormatters = patterns.map { pattern in
            let formatter = DateFormatter()
            formatter.dateFormat = pattern
            formatter.locale = Locale(identifier: "id_ID")
            return formatter
        }
    }

    func validate(_ receipt: ParsedReceipt, existingTransactions: [Transaction], now: Date = .now) -> ReceiptValidationResult {
        var errors: [String] = []

        var amountMinorUnits: Int64?
        if receipt.amount > 0 {
            amountMinorUnits = Int64(receipt.amount.rounded())
        } else {
            errors.append("Amount must be greater than zero.")
        }

        let parsedDate = parseDate(receipt.dateText)
        var date = parsedDate
        if parsedDate == nil {
            errors.append("Could not parse the receipt date.")
        } else if let parsedDate, parsedDate > now {
            errors.append("Date cannot be in the future.")
            date = nil
        }

        let duplicate: Transaction? = amountMinorUnits.flatMap { amount in
            existingTransactions.first { transaction in
                !transaction.isRecurringTemplate &&
                    transaction.amountMinorUnits == amount &&
                    abs(transaction.date.timeIntervalSince(date ?? now)) < 60 * 60 * 24
            }
        }

        return ReceiptValidationResult(
            amountMinorUnits: amountMinorUnits,
            date: date,
            errors: errors,
            possibleDuplicate: duplicate
        )
    }

    private func parseDate(_ text: String) -> Date? {
        for formatter in dateFormatters {
            if let date = formatter.date(from: text) {
                return date
            }
        }
        return nil
    }
}
