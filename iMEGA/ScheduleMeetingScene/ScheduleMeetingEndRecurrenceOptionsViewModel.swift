import MEGADomain

final class ScheduleMeetingEndRecurrenceOptionsViewModel: ObservableObject {

    @Published
    var endRecurrenceDate: Date {
        didSet {
            rules.until = endRecurrenceDate
        }
    }
    
    @Published
    private(set) var rules: ScheduledMeetingRulesEntity
    let startDate: Date

    init(rules: ScheduledMeetingRulesEntity, startDate: Date) {
        self.rules = rules
        self.startDate = startDate
        self.endRecurrenceDate = rules.until ?? Calendar.autoupdatingCurrent.date(byAdding: .month, value: 6, to: startDate) ?? Date()
    }
    
    func endRecurrenceNeverSelected() {
        rules.until = nil
    }
    
    func endRecurrenceSelected() {
        rules.until = endRecurrenceDate
    }
}
