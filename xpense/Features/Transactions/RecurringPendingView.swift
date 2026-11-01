import SwiftUI

/// Shown at launch for recurring schedules that are due and marked
/// "confirm before posting". Resolves one at a time; dismisses itself once
/// the queue is empty.
struct RecurringPendingView: View {
    @State private var viewModel: RecurringPendingViewModel
    let onFinished: () -> Void

    init(initialQueue: [PendingRecurringTransaction], service: RecurringTransactionService, onFinished: @escaping () -> Void) {
        _viewModel = State(initialValue: RecurringPendingViewModel(initialQueue: initialQueue, service: service))
        self.onFinished = onFinished
    }

    var body: some View {
        NavigationStack {
            if let current = viewModel.queue.first {
                Form {
                    Section("Recurring transaction due") {
                        Text(current.schedule.templateTransaction.category?.name ?? current.schedule.templateTransaction.note)
                        Text(CurrencyFormatting.format(
                            minorUnits: current.schedule.templateTransaction.amountMinorUnits,
                            currencyCode: current.schedule.templateTransaction.sourceWallet?.currencyCode ?? "IDR"
                        ))
                        Text(current.dueDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
                .navigationTitle("Confirm Recurring")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Skip") { viewModel.skipFirst() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Post") { viewModel.confirmFirst() }
                    }
                }
            } else {
                ContentUnavailableView("All caught up", systemImage: "checkmark.circle")
            }
        }
        .onChange(of: viewModel.queue.isEmpty) { _, isEmpty in
            if isEmpty { onFinished() }
        }
    }
}

#Preview {
    RecurringPendingView(
        initialQueue: [],
        service: DefaultRecurringTransactionService(
            transactionRepository: MockTransactionRepository(),
            scheduleRepository: MockRecurringScheduleRepository()
        ),
        onFinished: {}
    )
}
