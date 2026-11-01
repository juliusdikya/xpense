import SwiftUI

struct BudgetRow: View {
    let progress: BudgetProgress

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(progress.budget.category?.name ?? "Overall")
            ProgressView(value: min(progress.percentUsed, 100), total: 100)
                .tint(progress.isOverBudget ? .red : (progress.isWarning ? .orange : .accentColor))
            Text("\(spentText) of \(limitText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var currency: String { "IDR" }

    private var spentText: String {
        CurrencyFormatting.format(minorUnits: progress.spentMinorUnits, currencyCode: currency)
    }

    private var limitText: String {
        CurrencyFormatting.format(minorUnits: progress.budget.limitMinorUnits, currencyCode: currency)
    }
}
