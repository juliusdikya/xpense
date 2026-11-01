import SwiftUI

struct RecurringScheduleRow: View {
    let schedule: RecurringSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(schedule.templateTransaction.category?.name ?? schedule.templateTransaction.note)
            Text("\(frequencyText) · next \(schedule.nextDueDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var frequencyText: String {
        switch schedule.frequency {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .custom: return "Every \(schedule.customIntervalDays ?? 0) days"
        }
    }
}
