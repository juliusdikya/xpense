import Foundation

struct MonthlySummary {
    let totalIncomeMinorUnits: Int64
    let totalExpenseMinorUnits: Int64

    var netMinorUnits: Int64 { totalIncomeMinorUnits - totalExpenseMinorUnits }
}

/// Pure aggregation math, no SwiftData. Transfers and adjustments never
/// count toward income/expense totals.
protocol ReportingService {
    /// The period containing `date` for a configurable "month starts on day N" boundary.
    func monthRange(containing date: Date, monthStartDay: Int) -> ClosedRange<Date>
    func monthlySummary(transactions: [Transaction], range: ClosedRange<Date>) -> MonthlySummary
    func totalBalance(wallets: [Wallet], transactions: [Transaction]) -> Int64
    func dailyAverageExpense(transactions: [Transaction], range: ClosedRange<Date>) -> Int64
}

struct ReportingCalculator: ReportingService {
    private let balanceCalculator: BalanceCalculating
    private let calendar: Calendar

    init(balanceCalculator: BalanceCalculating = BalanceCalculator(), calendar: Calendar = .current) {
        self.balanceCalculator = balanceCalculator
        self.calendar = calendar
    }

    func monthRange(containing date: Date, monthStartDay: Int) -> ClosedRange<Date> {
        let day = calendar.component(.day, from: date)
        var anchorComponents: DateComponents
        if day < monthStartDay {
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: date) ?? date
            anchorComponents = calendar.dateComponents([.year, .month], from: previousMonth)
        } else {
            anchorComponents = calendar.dateComponents([.year, .month], from: date)
        }
        anchorComponents.day = monthStartDay

        let start = calendar.startOfDay(for: calendar.date(from: anchorComponents) ?? date)
        let nextStart = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let end = calendar.date(byAdding: .second, value: -1, to: nextStart) ?? nextStart
        return start...end
    }

    func monthlySummary(transactions: [Transaction], range: ClosedRange<Date>) -> MonthlySummary {
        var income: Int64 = 0
        var expense: Int64 = 0
        for transaction in transactions where !transaction.isRecurringTemplate && range.contains(transaction.date) {
            switch transaction.type {
            case .income:
                income += transaction.amountMinorUnits
            case .expense:
                expense += transaction.amountMinorUnits
            case .transfer, .adjustment:
                break
            }
        }
        return MonthlySummary(totalIncomeMinorUnits: income, totalExpenseMinorUnits: expense)
    }

    func totalBalance(wallets: [Wallet], transactions: [Transaction]) -> Int64 {
        wallets
            .filter { !$0.isArchived && !$0.excludeFromTotal }
            .reduce(Int64(0)) { total, wallet in
                total + balanceCalculator.balance(wallet: wallet, transactions: transactions)
            }
    }

    func dailyAverageExpense(transactions: [Transaction], range: ClosedRange<Date>) -> Int64 {
        let days = max(1, (calendar.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day ?? 0) + 1)
        let totalExpense = monthlySummary(transactions: transactions, range: range).totalExpenseMinorUnits
        return totalExpense / Int64(days)
    }
}
