import MEGADomain

extension ScheduledMeetingRulesEntity {
    
    mutating func reset(toFrequency frequency: Frequency, usingStartDate startDate: Date) {
        updateFrequency(frequency: frequency)
        updateDayList(usingStartDate: startDate)
    }
    
    mutating func updateDayList(usingStartDate startDate: Date) {
        switch frequency {
        case .invalid:
            self = ScheduledMeetingRulesEntity(
                frequency: frequency,
                interval: interval,
                until: until,
                monthDayList: nil,
                weekDayList: nil,
                monthWeekDayList: nil
            )
        case .daily:
            self = ScheduledMeetingRulesEntity(
                frequency: frequency,
                interval: interval,
                until: until,
                monthDayList: nil,
                weekDayList: Array(1...7),
                monthWeekDayList: nil
            )
        case .weekly:
            let weekDay = Calendar(identifier: .gregorian).component(.weekday, from: startDate)
            let weekDayList =  [((weekDay + 5) % 7) + 1]
            guard weekDayList != self.weekDayList else { return }
            self = ScheduledMeetingRulesEntity(
                frequency: frequency,
                interval: interval,
                until: until,
                monthDayList: nil,
                weekDayList: weekDayList,
                monthWeekDayList: nil
            )
        case .monthly:
            guard let day = Calendar.current.dateComponents([.day], from: startDate).day else { return }
            let monthDayList = [day]
            guard monthDayList != self.monthDayList else { return }
            self = ScheduledMeetingRulesEntity(
                frequency: frequency,
                interval: interval,
                until: until,
                monthDayList: monthDayList,
                weekDayList: nil,
                monthWeekDayList: nil
            )
        }
    }
        
    // MARK: - Private methods.
    
    private mutating func updateFrequency(frequency: Frequency) {
        self = ScheduledMeetingRulesEntity(
            frequency: frequency,
            interval: interval,
            until: until,
            monthDayList: monthDayList,
            weekDayList: weekDayList,
            monthWeekDayList: monthWeekDayList
        )
    }
}
    
