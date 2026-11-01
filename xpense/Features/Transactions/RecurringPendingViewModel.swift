import Foundation

@Observable
@MainActor
final class RecurringPendingViewModel {
    private(set) var queue: [PendingRecurringTransaction]
    private(set) var errorMessage: String?

    private let service: RecurringTransactionService

    init(initialQueue: [PendingRecurringTransaction], service: RecurringTransactionService) {
        self.queue = initialQueue
        self.service = service
    }

    func confirmFirst() {
        guard let first = queue.first else { return }
        do {
            try service.confirm(first)
            queue.removeFirst()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func skipFirst() {
        guard let first = queue.first else { return }
        do {
            try service.skip(first)
            queue.removeFirst()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
