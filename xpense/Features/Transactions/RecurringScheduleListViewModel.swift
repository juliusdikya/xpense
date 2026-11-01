import Foundation

@Observable
@MainActor
final class RecurringScheduleListViewModel {
    private(set) var schedules: [RecurringSchedule] = []
    private(set) var errorMessage: String?

    private let scheduleRepository: RecurringScheduleRepository

    init(scheduleRepository: RecurringScheduleRepository) {
        self.scheduleRepository = scheduleRepository
    }

    func load() {
        do {
            schedules = try scheduleRepository.fetchAll(includeInactive: false)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deactivate(_ schedule: RecurringSchedule) {
        do {
            try scheduleRepository.deactivate(schedule)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
