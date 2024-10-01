import MEGADomain
import MEGAL10n
import RegexBuilder

struct ScheduledMeetingDateBuilder {
    enum Formatter {
        case first
        case last
        case all
    }
    
    let scheduledMeeting: ScheduledMeetingEntity
    
    func buildDateDescriptionString(
        removingFormatter formatter: Formatter = .all,
        startDate: Date? = nil,
        endDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let description = descriptionString(
            locale: locale,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime
        )
        
        switch formatter {
        case .first:
            return removeFirstFormatter(fromString: description)
        case .last:
            return removeLastFormatter(fromString: description)
        case .all:
            return removeFormatters(fromString: description)
        }
    }
    
    // MARK: - Private methods
    
    private func descriptionString(
        locale: Locale,
        startDate: Date? = nil,
        endDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) -> String {
        let timeFormatter = DateFormatter.timeShort(locale: locale)
        let dateFormatter = DateFormatter.dateMedium(locale: locale)
        
        let startDate = startDate ?? scheduledMeeting.startDate
        let endDate = (endDate ?? scheduledMeeting.rules.until) ?? scheduledMeeting.endDate
        let startTime = startTime ?? scheduledMeeting.startDate
        let endTime = endTime ?? scheduledMeeting.endDate
        
        let startDateString = dateFormatter.localisedString(from: startDate)
        let endDateString = dateFormatter.localisedString(from: endDate)
        let startTimeString = timeFormatter.localisedString(from: startTime)
        let endTimeString = timeFormatter.localisedString(from: endTime)
        
        switch scheduledMeeting.rules.frequency {
        case .invalid:
            return oneOffDateString(startDate, startDateString, startTimeString, endTimeString)
        case .daily:
            return dailyDateString(startDateString, endDateString, startTimeString, endTimeString)
        case .weekly:
            return weeklyDateString(startDateString, endDateString, startTimeString, endTimeString)
        case .monthly:
            return monthlyDateString(startDateString, endDateString, startTimeString, endTimeString)
        }
    }
    
    private func oneOffDateString(_ startDate: Date, _ startDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        Strings.Localizable.Meetings.Scheduled.oneOff
            .replacingOccurrences(of: "[WeekDay]", with: DateFormatter.fromTemplate("E").localisedString(from: startDate))
            .replacingOccurrences(of: "[StartDate]", with: startDateString)
            .replacingOccurrences(of: "[StartTime]", with: startTimeString)
            .replacingOccurrences(of: "[EndTime]", with: endTimeString)
    }
    
    private func dailyDateString(_ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        if scheduledMeeting.rules.until != nil {
            let format = Strings.localized("meetings.scheduled.recurring.daily.until", comment: "")
            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
        } else {
            let format = Strings.localized("meetings.scheduled.recurring.daily.forever", comment: "")
            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
        }
    }
    
    private func weeklyDateString(_ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        guard let weekDaysList = scheduledMeeting.rules.weekDayList else {
            MEGALogError("weekDayList not found in rules of a weekly scheduled meeting")
            return ""
        }
        
        if Set(weekDaysList) == Set(1...7), scheduledMeeting.rules.interval == 1 {
            return dailyDateString(startDateString, endDateString, startTimeString, endTimeString)
        } else if weekDaysList.count == 1 {
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.weekly.oneDay.until", comment: "")
                return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                    .replacingOccurrences(of: "[WeekDay]", with: stringRepresentingWeekDayShortName(forNumber: weekDaysList.first))
                    .replacingOccurrences(of: "[StartDate]", with: startDateString)
                    .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                    .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                    .replacingOccurrences(of: "[EndTime]", with: endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.weekly.oneDay.forever", comment: "")
                return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                    .replacingOccurrences(of: "[WeekDay]", with: stringRepresentingWeekDayShortName(forNumber: weekDaysList.first))
                    .replacingOccurrences(of: "[StartDate]", with: startDateString)
                    .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                    .replacingOccurrences(of: "[EndTime]", with: endTimeString)
            }
        } else {
            let weekdayStringList = weekDaysList
                .compactMap {
                    $0 == weekDaysList.last
                    ? nil
                    : stringRepresentingWeekDayShortName(forNumber: $0, isAtTheStartOfSentence: $0 == weekDaysList.first)
                }
                .joined(separator: ", ")
            let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDaysList.last, isAtTheStartOfSentence: false)
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.weekly.severalDays.until", comment: "")
                return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                    .replacingOccurrences(of: "[WeekDaysList]", with: weekdayStringList)
                    .replacingOccurrences(of: "[LastWeekDay]", with: lastWeekdayString)
                    .replacingOccurrences(of: "[StartDate]", with: startDateString)
                    .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                    .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                    .replacingOccurrences(of: "[EndTime]", with: endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.weekly.severalDays.forever", comment: "")
                return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                    .replacingOccurrences(of: "[WeekDaysList]", with: weekdayStringList)
                    .replacingOccurrences(of: "[LastWeekDay]", with: lastWeekdayString)
                    .replacingOccurrences(of: "[StartDate]", with: startDateString)
                    .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                    .replacingOccurrences(of: "[EndTime]", with: endTimeString)
            }
        }
    }
    
    private func monthlySingleDayDateString(_ dayOfTheMonth: Int, _ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        if scheduledMeeting.rules.until != nil {
            let format = Strings.localized("meetings.scheduled.recurring.monthly.singleDay.until", comment: "")
            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                .replacingOccurrences(of: "[MonthDay]", with: String(dayOfTheMonth))
                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
        } else {
            let format = Strings.localized("meetings.scheduled.recurring.monthly.singleDay.forever", comment: "")
            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                .replacingOccurrences(of: "[MonthDay]", with: String(dayOfTheMonth))
                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
        }
    }
    
    private func monthlyMondayDateString(_ weekOfMonth: ScheduledMeetingEntity.WeekOfMonth, _ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        switch weekOfMonth {
        case .first:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.first", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.first", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .second:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.second", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.second", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .third:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.third", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.third", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fourth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.fourth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.fourth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fifth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.fifth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.fifth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        }
    }
    
    private func monthlyTuesdayDateString(_ weekOfMonth: ScheduledMeetingEntity.WeekOfMonth, _ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        switch weekOfMonth {
        case .first:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.first", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.first", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .second:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.second", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.second", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .third:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.third", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.third", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fourth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fourth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fourth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fifth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fifth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fifth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        }
    }
    
    private func monthlyWednesdayDateString(_ weekOfMonth: ScheduledMeetingEntity.WeekOfMonth, _ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        switch weekOfMonth {
        case .first:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.first", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.first", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .second:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.second", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.second", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .third:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.third", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.third", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fourth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.fourth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.fourth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fifth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.fifth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.fifth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        }
    }
    
    private func monthlyThursdayDateString(_ weekOfMonth: ScheduledMeetingEntity.WeekOfMonth, _ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        switch weekOfMonth {
        case .first:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.first", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.first", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .second:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.second", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.second", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .third:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.third", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.third", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fourth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.fourth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.fourth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fifth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.fifth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.fifth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        }
    }
    
    private func monthlyFridayDateString(_ weekOfMonth: ScheduledMeetingEntity.WeekOfMonth, _ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        switch weekOfMonth {
        case .first:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.first", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.first", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .second:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.second", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.second", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .third:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.third", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.third", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fourth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.fourth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.fourth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fifth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.fifth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.fifth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        }
    }
    
    private func monthlySaturdayDateString(_ weekOfMonth: ScheduledMeetingEntity.WeekOfMonth, _ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        switch weekOfMonth {
        case .first:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.first", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.first", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .second:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.second", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.second", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .third:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.third", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.third", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fourth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.fourth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.fourth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fifth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.fifth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.fifth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        }
    }
    
    private func monthlySundayDateString(_ weekOfMonth: ScheduledMeetingEntity.WeekOfMonth, _ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        switch weekOfMonth {
        case .first:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.first", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.first", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .second:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.second", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.second", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .third:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.third", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.third", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fourth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.fourth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.fourth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        case .fifth:
            if scheduledMeeting.rules.until != nil {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.fifth", comment: "")
                return monthlyUntilDateString(format, startDateString, endDateString, startTimeString, endTimeString)
            } else {
                let format = Strings.localized("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.fifth", comment: "")
                return monthlyForeverDateString(format, startDateString, startTimeString, endTimeString)
            }
        }
    }
    
    private func monthlyDateString(_ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        if let dayOfTheMonth = scheduledMeeting.rules.monthDayList?.first {
            return monthlySingleDayDateString(dayOfTheMonth, startDateString, endDateString, startTimeString, endTimeString)
        } else {
            guard let weekOfMonth = scheduledMeeting.weekOfMonth,
                  let weekday = scheduledMeeting.weekday else {
                MEGALogError("weekOfMonth or weekday  not found in monthWeekDayList rules of a monthly scheduled meeting")
                return ""
            }
            switch weekday {
            case .monday:
                return monthlyMondayDateString(weekOfMonth, startDateString, endDateString, startTimeString, endTimeString)
            case .tuesday:
                return monthlyTuesdayDateString(weekOfMonth, startDateString, endDateString, startTimeString, endTimeString)
            case .wednesday:
                return monthlyWednesdayDateString(weekOfMonth, startDateString, endDateString, startTimeString, endTimeString)
            case .thursday:
                return monthlyThursdayDateString(weekOfMonth, startDateString, endDateString, startTimeString, endTimeString)
            case .friday:
                return monthlyFridayDateString(weekOfMonth, startDateString, endDateString, startTimeString, endTimeString)
            case .saturday:
                return monthlySaturdayDateString(weekOfMonth, startDateString, endDateString, startTimeString, endTimeString)
            case .sunday:
                return monthlySundayDateString(weekOfMonth, startDateString, endDateString, startTimeString, endTimeString)
            }
        }
    }
    
    private func monthlyForeverDateString(_ format: String, _ startDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
            .replacingOccurrences(of: "[StartDate]", with: startDateString)
            .replacingOccurrences(of: "[StartTime]", with: startTimeString)
            .replacingOccurrences(of: "[EndTime]", with: endTimeString)
    }
    
    private func monthlyUntilDateString(_ format: String, _ startDateString: String, _ endDateString: String, _ startTimeString: String, _ endTimeString: String) -> String {
        return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
            .replacingOccurrences(of: "[StartDate]", with: startDateString)
            .replacingOccurrences(of: "[UntilDate]", with: endDateString)
            .replacingOccurrences(of: "[StartTime]", with: startTimeString)
            .replacingOccurrences(of: "[EndTime]", with: endTimeString)
    }
    
    private func stringRepresentingWeekDayShortName(forNumber number: Int?, isAtTheStartOfSentence: Bool = true) -> String {
        switch number {
        case 1:
            return isAtTheStartOfSentence
            ? Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.SentenceStart.Mon.title
            : Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.MidSentence.Mon.title
            
        case 2:
            return isAtTheStartOfSentence
            ? Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.SentenceStart.Tue.title
            : Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.MidSentence.Tue.title
            
        case 3:
            return isAtTheStartOfSentence
            ? Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.SentenceStart.Wed.title
            : Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.MidSentence.Wed.title
            
        case 4:
            return isAtTheStartOfSentence
            ? Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.SentenceStart.Thu.title
            : Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.MidSentence.Thu.title
            
        case 5:
            return isAtTheStartOfSentence
            ? Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.SentenceStart.Fri.title
            : Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.MidSentence.Fri.title
            
        case 6:
            return isAtTheStartOfSentence
            ? Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.SentenceStart.Sat.title
            : Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.MidSentence.Sat.title
            
        case 7:
            return isAtTheStartOfSentence
            ? Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.SentenceStart.Sun.title
            : Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.MidSentence.Sun.title
                        
        default:
            return ""
        }
    }
    
    @available(iOS 16.0, *)
    private func boldTagRegex() -> some RegexComponent {
        Regex {
            "["
            Capture {
                Optionally("/")
                One(.word)
            }
            "]"
        }
    }
    
    private func removeFormatters(fromString string: String) -> String {
        var formattedString = string
        if #available(iOS 16.0, *) {
            formattedString.replace(boldTagRegex(), with: "")
        } else {
            formattedString = formattedString.replacingOccurrences(of: #"\[.{1,2}\]"#, with: "", options: .regularExpression)
        }
        
        return formattedString
    }
    
    private func removeFirstFormatter(fromString string: String) -> String {
        var formattedString = string
        if #available(iOS 16.0, *) {
            formattedString.replace(boldTagRegex(), with: "", maxReplacements: 2)
        } else {
            if let range = formattedString.range(of: #"\[.{2}\]"#, options: [.regularExpression, .backwards]) {
                formattedString = formattedString.replacingOccurrences(of: #"\[.{1,2}\]"#, with: "", options: .regularExpression, range: formattedString.startIndex..<range.upperBound)
            }
        }
        
        return formattedString
    }
    
    private func removeLastFormatter(fromString string: String) -> String {
        var formattedString = string
        if #available(iOS 16.0, *) {
            formattedString.ranges(of: boldTagRegex()).suffix(2).reversed().forEach { range in
                formattedString.replaceSubrange(range, with: "")
            }
        } else {
            if let range = formattedString.range(of: #"\[.{2}\]"#, options: [.regularExpression, .backwards]) {
                formattedString = formattedString.replacingOccurrences(of: #"\[.{1,2}\]"#, with: "", options: .regularExpression, range: range.upperBound..<formattedString.endIndex)
            }
        }
        
        return formattedString
    }
    
}
