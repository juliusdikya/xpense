import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(
        walletRepository: WalletRepository,
        transactionRepository: TransactionRepository,
        reportingService: ReportingService
    ) {
        _viewModel = State(initialValue: DashboardViewModel(
            walletRepository: walletRepository,
            transactionRepository: transactionRepository,
            reportingService: reportingService
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Total Balance") {
                    Text(CurrencyFormatting.format(minorUnits: viewModel.totalBalanceMinorUnits, currencyCode: "IDR"))
                        .font(.title2.bold())
                }
                Section("This Month") {
                    LabeledContent("Income", value: CurrencyFormatting.format(
                        minorUnits: viewModel.summary.totalIncomeMinorUnits, currencyCode: "IDR"
                    ))
                    LabeledContent("Expense", value: CurrencyFormatting.format(
                        minorUnits: viewModel.summary.totalExpenseMinorUnits, currencyCode: "IDR"
                    ))
                    LabeledContent("Net", value: CurrencyFormatting.format(
                        minorUnits: viewModel.summary.netMinorUnits, currencyCode: "IDR"
                    ))
                }
                Section("Recent Transactions") {
                    if viewModel.recentTransactions.isEmpty {
                        Text("No transactions yet").foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.recentTransactions, id: \.id) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .onAppear { viewModel.load() }
        }
    }
}

#Preview {
    DashboardView(
        walletRepository: MockWalletRepository(),
        transactionRepository: MockTransactionRepository(),
        reportingService: ReportingCalculator()
    )
}
