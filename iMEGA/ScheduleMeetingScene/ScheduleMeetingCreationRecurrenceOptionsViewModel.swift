import MEGADomain

final class ScheduleMeetingCreationRecurrenceOptionsViewModel: ObservableObject {
    private let router: ScheduleMeetingCreationRecurrenceOptionsRouter
    
    @Published
    private(set) var rules: ScheduledMeetingRulesEntity
    
    private let startDate: Date
        
    lazy var selectedOption: ScheduleMeetingCreationRecurrenceOption = ScheduleMeetingCreationRecurrenceOption(rules: rules) {
        didSet {
            updateSelection(withRecurrenceOption: selectedOption)
        }
    }
    
    init(router: ScheduleMeetingCreationRecurrenceOptionsRouter) {
        self.router = router
        self.rules = router.rules
        self.startDate = router.startDate
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

    private func updateSelection(withRecurrenceOption recurrenceOption: ScheduleMeetingCreationRecurrenceOption) {
        guard recurrenceOption != .custom else {
            return
        }
                 
        let frequency = revelantFrequencey(forRecurrenceOption: recurrenceOption)
        rules.reset(toFrequency: frequency, usingStartDate: startDate)
        router.dismiss()
    }
    
    private func revelantFrequencey(forRecurrenceOption recurrenceOption: ScheduleMeetingCreationRecurrenceOption) -> ScheduledMeetingRulesEntity.Frequency {
        let frequency: ScheduledMeetingRulesEntity.Frequency
        
        switch recurrenceOption {
        case .daily:
            frequency = .daily
        case .weekly:
            frequency = .weekly
        case .monthly:
            frequency = .monthly
        default:
            frequency = .invalid
        }
        
        return frequency
    }
}



