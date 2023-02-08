import MEGADomain

struct ScheduledMeetingDateBuilder {
    private let scheduledMeeting: ScheduledMeetingEntity
    private var chatRoom: ChatRoomEntity?

    init(scheduledMeeting: ScheduledMeetingEntity,
         chatRoom: ChatRoomEntity?) {
        self.scheduledMeeting = scheduledMeeting
        self.chatRoom = chatRoom
    }
    
    func buildDateDescriptionString() -> String {
        let timeFormatter = DateFormatter.timeShort()
        let dateFormatter = DateFormatter.dateMedium()
        
        let startDate = dateFormatter.localisedString(from: scheduledMeeting.startDate)
        let startTime = timeFormatter.localisedString(from: scheduledMeeting.startDate)
        let endTime = timeFormatter.localisedString(from: scheduledMeeting.endDate)

        switch scheduledMeeting.rules.frequency {
        case .invalid:
            if scheduledMeeting.endDate < Date(), let chatRoom {
                return Strings.Localizable.Meetings.Panel.participantsCount(chatRoom.peers.count + 1)
            } else {
                let dayString = stringRepresentingWeekDayShortName(forNumber: Calendar.current.dateComponents([.weekday], from: scheduledMeeting.startDate).weekday)
                return Strings.Localizable.Meetings.Scheduled.oneOff(dayString, startDate, startTime, endTime)
            }
        case .daily:
            if let until = scheduledMeeting.rules.until {
                return Strings.Localizable.Meetings.Scheduled.Recurring.Daily.until(startDate, dateFormatter.localisedString(from: until), startTime, endTime)
            } else {
                return  Strings.Localizable.Meetings.Scheduled.Recurring.Daily.forever(startDate, startTime, endTime)
            }
        case .weekly:
            guard let weekDaysList = scheduledMeeting.rules.weekDayList else {
                MEGALogError("weekDayList not found in rules of a weekly scheduled meeting")
                return ""
            }
            if weekDaysList.count == 1 {
                if let until = scheduledMeeting.rules.until {
                    let format = NSLocalizedString("meetings.scheduled.recurring.weekly.oneDay.until", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[WeekDay]", with: stringRepresentingWeekDayShortName(forNumber: weekDaysList.first))
                        .replacingOccurrences(of: "[StartDate]", with: startDate)
                        .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                        .replacingOccurrences(of: "[StartTime]", with: startTime)
                        .replacingOccurrences(of: "[EndTime]", with: endTime)
                } else {
                    let format = NSLocalizedString("meetings.scheduled.recurring.weekly.oneDay.forever", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[WeekDay]", with: stringRepresentingWeekDayShortName(forNumber: weekDaysList.first))
                        .replacingOccurrences(of: "[StartDate]", with: startDate)
                        .replacingOccurrences(of: "[StartTime]", with: startTime)
                        .replacingOccurrences(of: "[EndTime]", with: endTime)
                }
            } else {
                let weekdayStringList = weekDaysList
                    .compactMap {  $0 == weekDaysList.last ? nil : stringRepresentingWeekDayShortName(forNumber: $0) }
                    .joined(separator: ", ")
                let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDaysList[weekDaysList.count - 1])
                if let until = scheduledMeeting.rules.until {
                    let format = NSLocalizedString("meetings.scheduled.recurring.weekly.severalDays.until", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[WeekDaysList]", with: weekdayStringList)
                        .replacingOccurrences(of: "[LastWeekDay]", with: lastWeekdayString)
                        .replacingOccurrences(of: "[StartDate]", with: startDate)
                        .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                        .replacingOccurrences(of: "[StartTime]", with: startTime)
                        .replacingOccurrences(of: "[EndTime]", with: endTime)
                } else {
                    let format = NSLocalizedString("meetings.scheduled.recurring.weekly.severalDays.forever", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[WeekDaysList]", with: weekdayStringList)
                        .replacingOccurrences(of: "[LastWeekDay]", with: lastWeekdayString)
                        .replacingOccurrences(of: "[StartDate]", with: startDate)
                        .replacingOccurrences(of: "[StartTime]", with: startTime)
                        .replacingOccurrences(of: "[EndTime]", with: endTime)
                }
            }
        case .monthly:
            if let dayOfTheMonth = scheduledMeeting.rules.monthDayList?.first {
                if let until = scheduledMeeting.rules.until {
                    let format = NSLocalizedString("meetings.scheduled.recurring.monthly.singleDay.until", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[MonthDay]", with: String(dayOfTheMonth))
                        .replacingOccurrences(of: "[StartDate]", with: startDate)
                        .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                        .replacingOccurrences(of: "[StartTime]", with: startTime)
                        .replacingOccurrences(of: "[EndTime]", with: endTime)
                } else {
                    let format = NSLocalizedString("meetings.scheduled.recurring.monthly.singleDay.forever", comment: "")
                    return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                        .replacingOccurrences(of: "[MonthDay]", with: String(dayOfTheMonth))
                        .replacingOccurrences(of: "[StartDate]", with: startDate)
                        .replacingOccurrences(of: "[StartTime]", with: startTime)
                        .replacingOccurrences(of: "[EndTime]", with: endTime)
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
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .second:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .third:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fourth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fifth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.monday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.monday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    }
                case .tuesday:
                    switch weekOfMonth {
                    case .first:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .second:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .third:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fourth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fifth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    }
                case .wednesday:
                    switch weekOfMonth {
                    case .first:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .second:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .third:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fourth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fifth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    }
                case .thursday:
                    switch weekOfMonth {
                    case .first:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .second:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .third:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fourth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fifth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    }
                case .friday:
                    switch weekOfMonth {
                    case .first:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .second:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .third:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fourth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fifth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    }
                case .saturday:
                    switch weekOfMonth {
                    case .first:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .second:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .third:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fourth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fifth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    }
                case .sunday:
                    switch weekOfMonth {
                    case .first:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.first", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .second:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.second", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .third:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.third", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fourth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fourth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    case .fifth:
                        if let until = scheduledMeeting.rules.until {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.until.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[UntilDate]", with: dateFormatter.localisedString(from: until))
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        } else {
                            let format = NSLocalizedString("meetings.scheduled.recurring.monthly.ordinalDay.forever.tuesday.fifth", comment: "")
                            return String(format: format, scheduledMeeting.rules.interval == 0 ? 1 : scheduledMeeting.rules.interval)
                                .replacingOccurrences(of: "[StartDate]", with: startDate)
                                .replacingOccurrences(of: "[StartTime]", with: startTime)
                                .replacingOccurrences(of: "[EndTime]", with: endTime)
                        }
                    }
                }
            }
        }
    }
    
    private func stringRepresentingWeekDayShortName(forNumber number: Int?) -> String {
        switch number {
        case 1: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Mon.title
        case 2: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Tue.title
        case 3: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Wed.title
        case 4: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Thu.title
        case 5: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Fri.title
        case 6: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Sat.title
        case 7: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Sun.title
        default: return ""
        }
    }
}
