import MEGADomain

protocol ScheduleMeetingCreationRecurrenceOptionsRouting {
    var rules: ScheduledMeetingRulesEntity { get }
    var startDate: Date { get }
    @discardableResult
    func start() -> ScheduleMeetingCreationRecurrenceOptionsViewModel
    func navigateToCustomOptionsScreen()
    func dismiss()
}

final class ScheduleMeetingCreationRecurrenceOptionsViewModel: ObservableObject {
    private let router: ScheduleMeetingCreationRecurrenceOptionsRouting
    private let startDate: Date

    @Published
    private(set) var rules: ScheduledMeetingRulesEntity
    
    @Published
    private(set) var selectedOption: ScheduleMeetingCreationRecurrenceOption
    
    init(router: ScheduleMeetingCreationRecurrenceOptionsRouting) {
        self.router = router
        self.startDate = router.startDate
        self.rules = router.rules
        self.selectedOption = ScheduleMeetingCreationRecurrenceOption(rules: router.rules, startDate: startDate)
    }
    
    func nonCustomizedOptions() -> [ScheduleMeetingCreationRecurrenceOption] {
        return [.never, .daily, .weekly, .monthly]
    }
    
    func customizedOption() -> ScheduleMeetingCreationRecurrenceOption {
        .custom
    }
    
    func customOptionFooterNote() -> String? {
        guard selectedOption == .custom else { return nil }
        return ScheduleMeetingCreationIntervalFooterNote(rules: rules).string
    }
    
    func updateUI() {
        self.rules = router.rules
        self.selectedOption = ScheduleMeetingCreationRecurrenceOption(rules: router.rules, startDate: startDate)
    }
    
    func navigateToCustomOptionsScreen() {
        router.navigateToCustomOptionsScreen()
    }

    func updateSelection(withRecurrenceOption recurrenceOption: ScheduleMeetingCreationRecurrenceOption) {
        guard recurrenceOption != .custom else {
            return
        }
                 
        let frequency = revelantFrequencey(forRecurrenceOption: recurrenceOption)
        rules.reset(toFrequency: frequency, usingStartDate: startDate)
    }
    
    func dismiss() {
        router.dismiss()
    }
    
    // MARK: - Private methods
    
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
