import Foundation
import SwiftData

protocol RecurringScheduleRepository {
    func fetchAll(includeInactive: Bool) throws -> [RecurringSchedule]
    func fetch(id: UUID) throws -> RecurringSchedule?
    @discardableResult
    func create(
        templateTransaction: Transaction,
        frequency: RecurrenceFrequency,
        customIntervalDays: Int?,
        nextDueDate: Date,
        requiresConfirmation: Bool
    ) throws -> RecurringSchedule
    func update(_ schedule: RecurringSchedule) throws
    func deactivate(_ schedule: RecurringSchedule) throws
}

@MainActor
final class SwiftDataRecurringScheduleRepository: RecurringScheduleRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(includeInactive: Bool) throws -> [RecurringSchedule] {
        let sort = [SortDescriptor(\RecurringSchedule.nextDueDate)]
        if includeInactive {
            return try modelContext.fetch(FetchDescriptor<RecurringSchedule>(sortBy: sort))
        }
        let predicate = #Predicate<RecurringSchedule> { $0.isActive }
        return try modelContext.fetch(FetchDescriptor<RecurringSchedule>(predicate: predicate, sortBy: sort))
    }

    func fetch(id: UUID) throws -> RecurringSchedule? {
        let predicate = #Predicate<RecurringSchedule> { $0.id == id }
        return try modelContext.fetch(FetchDescriptor<RecurringSchedule>(predicate: predicate)).first
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
        modelContext.insert(schedule)
        try save()
        return schedule
    }

    func update(_ schedule: RecurringSchedule) throws {
        try save()
    }

    func deactivate(_ schedule: RecurringSchedule) throws {
        schedule.isActive = false
        try save()
    }

    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed(underlying: error)
        }
    }
}
