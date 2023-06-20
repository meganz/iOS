import MEGADomain

final class ScheduleMeetingCreationWeeklyCustomOptionsViewModel: ObservableObject {
    private let weekDaysInformation = WeekDaysInformation()
    
    var weekdaySymbols: [String] {
        weekDaysInformation.symbols
    }
    
    var selectedWeekDays: Set<String>? {
        guard let weekDayList = rules.weekDayList else { return nil }
        return Set(weekDayList.map({ weekDaysInformation.symbols[$0 - 1] }))
    }
    
    @Published
    private(set) var rules: ScheduledMeetingRulesEntity

    init(rules: ScheduledMeetingRulesEntity) {
        self.rules = rules
    }
    
    func updateWeekDayList(_ selectedWeekDays: Set<String>?) {
        guard let selectedWeekDays else {
            rules.weekDayList = nil
            return
        }
        
        rules.weekDayList = convertToWeekDayList(selectedWeekDays: selectedWeekDays)
    }
    
    func toggleSelection(forWeekDay weekDay: String) {
        guard let weekDayInt = convertToWeekDayList(selectedWeekDays: [weekDay]).first else { return }
        
        guard var weekDayList = rules.weekDayList else {
            rules.weekDayList = [weekDayInt]
            return
        }
        
        if weekDayList.contains(weekDayInt) {
            weekDayList.remove(object: weekDayInt)
        } else {
            weekDayList.append(weekDayInt)
        }
        
        guard weekDayList.isNotEmpty else { return }
        rules.weekDayList = weekDayList.sorted()
    }
    
    func update(interval: Int) {
        rules.interval = interval
    }
    
    private func convertToWeekDayList(selectedWeekDays: Set<String>) -> [Int] {
        selectedWeekDays
            .compactMap({ weekDaysInformation.symbols.firstIndex(of: $0).map { $0 + 1} })
            .sorted()
    }
}
