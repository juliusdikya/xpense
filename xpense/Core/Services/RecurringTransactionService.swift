import Foundation

struct PendingRecurringTransaction: Identifiable {
    let id: UUID
    let schedule: RecurringSchedule
    let dueDate: Date
}

protocol RecurringTransactionService {
    /// Posts every due schedule that does not require confirmation,
    /// advancing its `nextDueDate`. Schedules that are due AND require
    /// confirmation are returned untouched, to be resolved via `confirm`/`skip`.
    @discardableResult
    func generateDueTransactions(asOf: Date) throws -> [PendingRecurringTransaction]
    func confirm(_ pending: PendingRecurringTransaction) throws
    func skip(_ pending: PendingRecurringTransaction) throws
}

@MainActor
final class DefaultRecurringTransactionService: RecurringTransactionService {
    private let transactionRepository: TransactionRepository
    private let scheduleRepository: RecurringScheduleRepository
    private let calendar: Calendar

    init(
        transactionRepository: TransactionRepository,
        scheduleRepository: RecurringScheduleRepository,
        calendar: Calendar = .current
    ) {
        self.transactionRepository = transactionRepository
        self.scheduleRepository = scheduleRepository
        self.calendar = calendar
    }

    @discardableResult
    func generateDueTransactions(asOf: Date) throws -> [PendingRecurringTransaction] {
        let schedules = try scheduleRepository.fetchAll(includeInactive: false)
        var pending: [PendingRecurringTransaction] = []
        for schedule in schedules where schedule.nextDueDate <= asOf {
            if schedule.requiresConfirmation {
                pending.append(PendingRecurringTransaction(id: schedule.id, schedule: schedule, dueDate: schedule.nextDueDate))
            } else {
                try post(schedule: schedule, dueDate: schedule.nextDueDate)
                try advance(schedule)
            }
        }
        return pending
    }

    func confirm(_ pending: PendingRecurringTransaction) throws {
        try post(schedule: pending.schedule, dueDate: pending.dueDate)
        try advance(pending.schedule)
    }

    func skip(_ pending: PendingRecurringTransaction) throws {
        try advance(pending.schedule)
    }

    private func post(schedule: RecurringSchedule, dueDate: Date) throws {
        let template = schedule.templateTransaction
        let transaction = Transaction(
            type: template.type,
            amountMinorUnits: template.amountMinorUnits,
            feeMinorUnits: template.feeMinorUnits,
            date: dueDate,
            note: template.note,
            tags: template.tags,
            sourceWallet: template.sourceWallet,
            destinationWallet: template.destinationWallet,
            category: template.category
        )
        try transactionRepository.create(transaction)
        schedule.lastGeneratedDate = dueDate
    }

    private func advance(_ schedule: RecurringSchedule) throws {
        schedule.nextDueDate = nextDate(
            after: schedule.nextDueDate,
            frequency: schedule.frequency,
            customIntervalDays: schedule.customIntervalDays
        )
        try scheduleRepository.update(schedule)
    }

    private func nextDate(after date: Date, frequency: RecurrenceFrequency, customIntervalDays: Int?) -> Date {
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .custom:
            return calendar.date(byAdding: .day, value: max(1, customIntervalDays ?? 1), to: date) ?? date
        }
    }
}
