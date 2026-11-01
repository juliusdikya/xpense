import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amountText)
                .foregroundStyle(amountColor)
        }
    }

    private var title: String {
        switch transaction.type {
        case .transfer:
            return "\(transaction.sourceWallet?.name ?? "-") → \(transaction.destinationWallet?.name ?? "-")"
        default:
            return transaction.category?.name ?? "Uncategorized"
        }
    }

    private var subtitle: String {
        transaction.note.isEmpty
            ? transaction.date.formatted(date: .abbreviated, time: .omitted)
            : transaction.note
    }

    private var amountText: String {
        let currency = transaction.sourceWallet?.currencyCode ?? "IDR"
        let signed = transaction.type == .expense ? -transaction.amountMinorUnits : transaction.amountMinorUnits
        return CurrencyFormatting.format(minorUnits: signed, currencyCode: currency)
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .red
        case .transfer, .adjustment: return .primary
        }
    }
}
