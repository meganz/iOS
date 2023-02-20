import MEGADomain

struct ScheduledMeetingDateBuilder {
    enum Formatter {
        case first
        case last
        case all
    }
    
    private let scheduledMeeting: ScheduledMeetingEntity
    private var chatRoom: ChatRoomEntity?

    init(scheduledMeeting: ScheduledMeetingEntity,
         chatRoom: ChatRoomEntity?) {
        self.scheduledMeeting = scheduledMeeting
        self.chatRoom = chatRoom
    }
    
    func buildDateDescriptionString(
        removingFormatter formatter: Formatter = .all,
        startDate: Date? = nil,
        endDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) -> String {
        let description = descriptionString(startDate: startDate, endDate: endDate, startTime: startTime, endTime: endTime)
        
        switch formatter {
        case .first:
            return removeFirstFormatter(fromString: description)
        case .last:
            return removeLastFormatter(fromString: description)
        case .all:
            return removeFormatters(fromString: description)
        }
    }
    
    //MARK: - Private methods
    
    private func descriptionString(
        startDate: Date? = nil,
        endDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) -> String {
        let timeFormatter = DateFormatter.timeShort()
        let dateFormatter = DateFormatter.dateMedium()
        
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
            if scheduledMeeting.endDate < Date(), let chatRoom {
                return Strings.Localizable.Meetings.Panel.participantsCount(chatRoom.peers.count + 1)
            } else {
                return Strings.Localizable.Meetings.Scheduled.oneOff
                    .replacingOccurrences(of: "[WeekDay]", with: DateFormatter.fromTemplate("E").localisedString(from: startDate))
                    .replacingOccurrences(of: "[StartDate]", with: startDateString)
                    .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                    .replacingOccurrences(of: "[EndTime]", with: endTimeString)
            }
        case .daily:
            if scheduledMeeting.rules.until != nil {
                return Strings.Localizable.Meetings.Scheduled.Recurring.Daily.until
                    .replacingOccurrences(of: "[StartDate]", with: startDateString)
                    .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                    .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                    .replacingOccurrences(of: "[EndTime]", with: endTimeString)
            } else {
                return Strings.Localizable.Meetings.Scheduled.Recurring.Daily.forever
                    .replacingOccurrences(of: "[StartDate]", with: startDateString)
                    .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                    .replacingOccurrences(of: "[EndTime]", with: endTimeString)
            }
        case .weekly:
            guard let weekDaysList = scheduledMeeting.rules.weekDayList else {
                MEGALogError("weekDayList not found in rules of a weekly scheduled meeting")
                return ""
            }
            if weekDaysList.count == 1 {
                if scheduledMeeting.rules.until != nil {
                    let format = NSLocalizedString("meetings.scheduled.recurring.weekly.oneDay.until", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[WeekDay]", with: stringRepresentingWeekDayShortName(forNumber: weekDaysList.first))
                        .replacingOccurrences(of: "[StartDate]", with: startDateString)
                        .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                        .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                        .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                } else {
                    let format = NSLocalizedString("meetings.scheduled.recurring.weekly.oneDay.forever", comment: "")
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
                    let format = NSLocalizedString("meetings.scheduled.recurring.weekly.severalDays.until", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[WeekDaysList]", with: weekdayStringList)
                        .replacingOccurrences(of: "[LastWeekDay]", with: lastWeekdayString)
                        .replacingOccurrences(of: "[StartDate]", with: startDateString)
                        .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                        .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                        .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                } else {
                    let format = NSLocalizedString("meetings.scheduled.recurring.weekly.severalDays.forever", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[WeekDaysList]", with: weekdayStringList)
                        .replacingOccurrences(of: "[LastWeekDay]", with: lastWeekdayString)
                        .replacingOccurrences(of: "[StartDate]", with: startDateString)
                        .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                        .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                }
            }
        case .monthly:
            if let dayOfTheMonth = scheduledMeeting.rules.monthDayList?.first {
                if scheduledMeeting.rules.until != nil {
                    let format = NSLocalizedString("meetings.scheduled.recurring.monthly.singleDay.until", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[MonthDay]", with: String(dayOfTheMonth))
                        .replacingOccurrences(of: "[StartDate]", with: startDateString)
                        .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                        .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                        .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                } else {
                    let format = NSLocalizedString("meetings.scheduled.recurring.monthly.singleDay.forever", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[MonthDay]", with: String(dayOfTheMonth))
                        .replacingOccurrences(of: "[StartDate]", with: startDateString)
                        .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                        .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                }
            } else {
                guard let weekOfMonth = scheduledMeeting.weekOfMonth,
                      let weekday = scheduledMeeting.weekday else {
                    MEGALogError("weekOfMonth or weekday  not found in monthWeekDayList rules of a monthly scheduled meeting")
                    return ""
                }
                switch weekday {
                case .monday:
                    switch weekOfMonth {
                    case .first:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .second:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .third:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fourth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fifth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    }
                case .tuesday:
                    switch weekOfMonth {
                    case .first:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .second:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .third:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fourth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fifth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    }
                case .wednesday:
                    switch weekOfMonth {
                    case .first:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .second:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .third:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fourth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fifth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.wednesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.wednesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    }
                case .thursday:
                    switch weekOfMonth {
                    case .first:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .second:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .third:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fourth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fifth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.thursday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.thursday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    }
                case .friday:
                    switch weekOfMonth {
                    case .first:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .second:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .third:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fourth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fifth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.friday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.friday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    }
                case .saturday:
                    switch weekOfMonth {
                    case .first:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .second:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .third:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fourth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fifth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.saturday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.saturday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    }
                case .sunday:
                    switch weekOfMonth {
                    case .first:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .second:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .third:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fourth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    case .fifth:
                        if scheduledMeeting.rules.until != nil {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.sunday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[UntilDate]", with: endDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.sunday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDateString)
                                .replacingOccurrences(of: "[StartTime]", with: startTimeString)
                                .replacingOccurrences(of: "[EndTime]", with: endTimeString)
                        }
                    }
                }
            }
        }

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
    
    private func removeFormatters(fromString string: String) -> String {
        var formattedString = string
        if #available(iOS 16.0, *) {
            formattedString.replace(/\[.{1, 2}\]/, with: "")
        } else {
            formattedString = formattedString.replacingOccurrences(of: #"\[.{1,2}\]"#, with: "", options: .regularExpression)
        }
        
        return formattedString
    }
    
    private func removeFirstFormatter(fromString string: String) -> String {
        var formattedString = string
        if #available(iOS 16.0, *) {
            formattedString.replace(/\[.{1, 2}\]/, with: "", maxReplacements: 2)
        } else {
            if let range = formattedString.range(of:  #"\[.{2}\]"#, options: [.regularExpression, .backwards]) {
                formattedString = formattedString.replacingOccurrences(of: #"\[.{1,2}\]"#, with: "", options: .regularExpression, range: formattedString.startIndex..<range.upperBound)
            }
        }
        
        return formattedString
    }
    
    private func removeLastFormatter(fromString string: String) -> String {
        var formattedString = string
        if #available(iOS 16.0, *) {
            formattedString.ranges(of: /\[.{1, 2}\]/).suffix(2).reversed().forEach { range in
                formattedString.replaceSubrange(range, with: "")
            }
        } else {
            if let range = formattedString.range(of:  #"\[.{2}\]"#, options: [.regularExpression, .backwards]) {
                formattedString = formattedString.replacingOccurrences(of: #"\[.{1,2}\]"#, with: "", options: .regularExpression, range: range.upperBound..<formattedString.endIndex)
            }
        }
        
        return formattedString
    }
    
}
