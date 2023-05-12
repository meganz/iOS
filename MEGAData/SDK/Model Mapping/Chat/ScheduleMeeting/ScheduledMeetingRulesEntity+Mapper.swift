import MEGADomain

extension MEGAChatScheduledRules {
    func toScheduledMeetingRulesEntity() -> ScheduledMeetingRulesEntity {
        ScheduledMeetingRulesEntity(with: self)
    }
}

extension MEGAChatScheduledRulesFrequency {
    func toScheduledMeetingRulesEntityFrequency() -> ScheduledMeetingRulesEntity.Frequency {
        switch self {
        case .invalid:
            return .invalid
        case .daily:
            return .daily
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        @unknown default:
            return .invalid
        }
    }
}

extension ScheduledMeetingRulesEntity.Frequency {
    func toMEGAChatScheduledRulesFrequency() -> MEGAChatScheduledRulesFrequency {
        switch self {
        case .invalid:
            return .invalid
        case .daily:
            return .daily
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        }
    }
}

extension ScheduledMeetingRulesEntity {
    init(with rules: MEGAChatScheduledRules) {
        var date: Date?
        if rules.until > 0 {
            date = Date(timeIntervalSince1970: TimeInterval(rules.until))
        }
        
        let monthDayList = rules.byMonthDay?.map(\.intValue).sorted()
        let weekDayList = rules.byWeekDay?.map(\.intValue).sorted()
        let monthWeekDayList = rules.byMonthWeekDay?.map { $0.map(\.intValue)}
        
        self.init(
            frequency: rules.frequency.toScheduledMeetingRulesEntityFrequency(),
            interval: rules.interval,
            until: date,
            monthDayList: monthDayList,
            weekDayList: weekDayList,
            monthWeekDayList: monthWeekDayList
        )
    }
    
    func toMEGAChatScheduledRules() -> MEGAChatScheduledRules {
        MEGAChatScheduledRules(
            frequency: frequency.toMEGAChatScheduledRulesFrequency(),
            interval: interval,
            until: UInt64(until?.timeIntervalSince1970 ?? 0),
            byWeekDay: weekDayList?.map(NSNumber.init(value:)),
            byMonthDay: monthDayList?.map(NSNumber.init(value:)),
            byMonthWeekDay: monthWeekDayList?.map { $0.map(NSNumber.init(value:)) }
        )
    }
}
