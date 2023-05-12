import MEGADomain

final class ScheduleMeetingCreationRecurrenceOptionsViewModel: ObservableObject {
    private let router: ScheduleMeetingCreationRecurrenceOptionsRouter
    
    @Published
    private(set) var rules: ScheduledMeetingRulesEntity
        
    lazy var selectedOption: ScheduleMeetingCreationRecurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules) {
        didSet {
            updateSelection()
        }
    }
    
    init(router: ScheduleMeetingCreationRecurrenceOptionsRouter) {
        self.router = router
        self.rules = router.rules
    }
    
    func recurrenceOptions(forSection section: Int) -> [ScheduleMeetingCreationRecurrenceOption] {
        switch section {
        case 0:
            return [.never, .daily, .weekly, .monthly]
        case 1:
            return [.custom]
        default:
            return []
        }
    }

    private func updateSelection() {
        guard selectedOption != .custom else {
            return
        }
         
        let frequency: ScheduledMeetingRulesEntity.Frequency
        var weekDayList: [Int]? = nil
        var monthDayList: [Int]? = nil
        
        switch selectedOption {
        case .daily:
            weekDayList = Array(1...7)
            frequency = .daily
        case .weekly:
            let weekDay = Calendar(identifier: .gregorian).component(.weekday, from: Date())
            weekDayList = [((weekDay + 5) % 7) + 1] // gregorian - 1 is Sunday but we need Monday as 1
            frequency = .weekly
        case .monthly:
            if let day = Calendar.current.dateComponents([.day], from: Date()).day {
                monthDayList = [day]
            }
            frequency = .monthly
        default:
            frequency = .invalid
            break
        }
        
        rules = ScheduledMeetingRulesEntity(
            frequency: frequency,
            interval: rules.interval,
            until: rules.until,
            monthDayList: monthDayList,
            weekDayList: weekDayList,
            monthWeekDayList: rules.monthWeekDayList
        )
        
        router.dismiss()
    }
}



