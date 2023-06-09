import MEGADomain

final class ScheduleMeetingEndRecurrenceOptionsViewModel: ObservableObject {
    private let router: ScheduleMeetingEndRecurrenceOptionsRouter

    @Published
    var endRecurrenceDate: Date {
        didSet {
            rules.until = endRecurrenceDate
        }
    }
    
    @Published
    private(set) var rules: ScheduledMeetingRulesEntity
    let startDate: Date

    init(router: ScheduleMeetingEndRecurrenceOptionsRouter, startDate: Date) {
        self.router = router
        self.rules = router.rules
        self.startDate = startDate
        self.endRecurrenceDate = router.rules.until ?? Calendar.autoupdatingCurrent.date(byAdding: .month, value: 6, to: startDate) ?? Date()
    }
    
    func endRecurrenceNeverSelected() {
        rules.until = nil
    }
    
    func endRecurrenceSelected() {
        rules.until = endRecurrenceDate
    }
}
