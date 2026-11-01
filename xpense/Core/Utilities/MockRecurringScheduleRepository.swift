import Foundation

/// In-memory mock for previews and tests. No SwiftData involved.
final class MockRecurringScheduleRepository: RecurringScheduleRepository {
    private(set) var schedules: [RecurringSchedule]

    init(schedules: [RecurringSchedule] = []) {
        self.schedules = schedules
    }

    func fetchAll(includeInactive: Bool) throws -> [RecurringSchedule] {
        includeInactive ? schedules : schedules.filter { $0.isActive }
    }

    func fetch(id: UUID) throws -> RecurringSchedule? {
        schedules.first { $0.id == id }
    }

    @discardableResult
    func create(
        templateTransaction: Transaction,
        frequency: RecurrenceFrequency,
        customIntervalDays: Int?,
        nextDueDate: Date,
        requiresConfirmation: Bool
    ) throws -> RecurringSchedule {
        let schedule = RecurringSchedule(
            frequency: frequency,
            customIntervalDays: customIntervalDays,
            nextDueDate: nextDueDate,
            requiresConfirmation: requiresConfirmation,
            templateTransaction: templateTransaction
        )
        schedules.append(schedule)
        return schedule
    }

    func update(_ schedule: RecurringSchedule) throws {}

    func deactivate(_ schedule: RecurringSchedule) throws {
        schedule.isActive = false
    }
}
