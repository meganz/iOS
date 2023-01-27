import MEGADomain
import MEGAFoundation

extension NotificationsTableViewController {
    
    // MARK: - Interface methods
    
    @objc func contentForNewScheduledMeeting(withAlert alert: MEGAUserAlert) -> NSAttributedString? {
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return nil
        }
        if scheduledMeeting.rules.frequency == .invalid {
            return contentForOneOffNewScheduledMeeting(scheduledMeeting, email: alert.email)
        } else if scheduledMeeting.rules.frequency == .daily {
            return contentForDailyNewScheduledMeeting(scheduledMeeting, email: alert.email)
        } else if scheduledMeeting.rules.frequency == .weekly {
            return contentForWeeklyNewScheduledMeeting(scheduledMeeting, email: alert.email)
        } else if scheduledMeeting.rules.frequency == .monthly {
            return contentForMonthlyNewScheduledMeeting(scheduledMeeting, email: alert.email)
        }
        
        return NSAttributedString(string: "Unhandled New meeting")
    }
    
    @objc func contentForUpdatedScheduledMeeting(withAlert alert: MEGAUserAlert) -> NSAttributedString? {
        guard let scheduledMeetingEntity = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return nil
        }
        
        if alert.hasScheduledMeetingChangeType(.cancelled) {
            if alert.hasScheduledMeetingChangeType(.rules) {
                return contentForRecurringCancelledScheduledMeeting(withEmail: alert.email)
            } else {
                return contentForOneOffCancelledScheduledMeeting(scheduledMeetingEntity, email: alert.email)
            }
        } else if checkIfMultipleFieldsHaveChangedForScheduledMeeting(in: alert)
            || alert.hasScheduledMeetingChangeType(.timeZone) {
            if scheduledMeetingEntity.rules.frequency == .invalid {
                return contentForOneOffScheduledMeetingWithMultipleFieldsChanged(scheduledMeeting: scheduledMeetingEntity, email: alert.email)
            } else if scheduledMeetingEntity.rules.frequency == .daily {
                return contentForDailyScheduledMeetingWithMultipleFieldsChanged(scheduledMeeting: scheduledMeetingEntity, email: alert.email)
            } else if scheduledMeetingEntity.rules.frequency == .weekly {
                return contentForWeeklyScheduledMeetingWithMultipleFieldsChanged(scheduledMeeting: scheduledMeetingEntity, email: alert.email)
            } else if scheduledMeetingEntity.rules.frequency == .monthly {
                return contentForMonthlyScheduledMeetingWithMultipleFieldsChanged(scheduledMeeting: scheduledMeetingEntity, email: alert.email)
            }
            
        }  else if alert.hasScheduledMeetingChangeType(.title) {
            let titleList = alert.titleList.toArray()
            return contentForScheduledMeetingTitleUpdate(
                withScheduleMeetingId: alert.scheduledMeetingId,
                chatId: alert.nodeHandle,
                email: alert.email,
                oldTitle: titleList.first,
                newTitle: titleList.last,
                isReccurring: scheduledMeetingEntity.rules.frequency != .invalid
            )
        } else if alert.hasScheduledMeetingChangeType(.description) {
            if scheduledMeetingEntity.rules.frequency == .invalid {
                return contentForOneOffScheduledMeetingWithDescriptionFieldChanged(scheduledMeeting: scheduledMeetingEntity, email: alert.email)
            } else if scheduledMeetingEntity.rules.frequency == .daily {
                return contentForDailyScheduledMeetingWithDescriptionFieldChanged(scheduledMeeting: scheduledMeetingEntity, email: alert.email)
            } else if scheduledMeetingEntity.rules.frequency == .weekly {
                return contentForWeeklyScheduledMeetingWithDescriptionFieldChanged(scheduledMeeting: scheduledMeetingEntity, email: alert.email)
            } else if scheduledMeetingEntity.rules.frequency == .monthly {
                return contentForMonthlyScheduledMeetingWithDescriptionFieldChanged(scheduledMeeting: scheduledMeetingEntity, email: alert.email)
            }
        } else if alert.hasScheduledMeetingChangeType(.startDate) || alert.hasScheduledMeetingChangeType(.endDate) {
            if scheduledMeetingEntity.rules.frequency == .invalid {
                return contentForOneOffScheduledMeetingWithDateFieldChanged(for: alert)
            } else if scheduledMeetingEntity.rules.frequency == .daily {
                return contentForDailyScheduledMeetingWithDateFieldChanged(for: alert)
            } else if scheduledMeetingEntity.rules.frequency == .weekly {
                return contentForWeeklyScheduledMeetingWithDateFieldChanged(for: alert)
            } else if scheduledMeetingEntity.rules.frequency == .monthly {
                return contentForMonthlyScheduledMeetingWithDateFieldChanged(for: alert)
            }
        } else if alert.hasScheduledMeetingChangeType(.rules) {
            return NSAttributedString(string: alert.title)
        }
        
        return NSAttributedString(string: alert.title)
    }
    
    @objc func scheduledMeeting(withScheduleMeetingId meetingId: ChatIdEntity, chatId: ChatIdEntity) -> MEGAChatScheduledMeeting? {
        MEGASdkManager.sharedMEGAChatSdk().scheduledMeeting(chatId, scheduledId: meetingId)
    }
    
    @objc func openChatRoom(forUserAlert alert: MEGAUserAlert) {
        guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else {
            return
        }
        
        navigationController?.popToRootViewController(animated: false)
        mainTabBarController.openChatRoom(chatId: alert.nodeHandle)
    }
    
    // MARK: Private methods
    
    private func contentForOneOffNewScheduledMeeting(_ scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        return contentForScheduledMeetingWithTwoPlaceholders(
            scheduledMeeting,
            email: email,
            localizedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.New.description
        )
    }
    
    private func contentForOneOffCancelledScheduledMeeting(_ scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        return contentForScheduledMeetingWithTwoPlaceholders(
            scheduledMeeting,
            email: email,
            localizedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.Cancelled.description
        )
    }
    
    private func contentForRecurringCancelledScheduledMeeting(withEmail email: String) -> NSAttributedString? {
        createAttributedStringWithOneBoldTag(
            content: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Cancelled.description(email)
        )
    }
    
    private func contentForScheduledMeetingWithTwoPlaceholders(
        _ scheduledMeeting: ScheduledMeetingEntity,
        email: String,
        localizedString: (Any, Any) -> String
    ) -> NSAttributedString? {
        let dateString = DateFormatter.fromTemplate("E, d MMM").localisedString(from: scheduledMeeting.startDate)
        + ", "
        + DateFormatter.fromTemplate("yyyy").localisedString(from: scheduledMeeting.startDate)
        + " • "
        + DateFormatter.fromTemplate("h:mm").localisedString(from: scheduledMeeting.startDate)
        + " - "
        + DateFormatter.fromTemplate("h:mm").localisedString(from: scheduledMeeting.endDate)
        
        return createAttributedStringWithOneBoldTag(content: localizedString(email, dateString))
    }
    
    private func createAttributedStringWithOneBoldTag(content: String) -> NSAttributedString? {
        let attributedContent = NSMutableAttributedString(string: content, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
        let lowerRange = attributedContent.mutableString.range(of: "[B]")
        let upperRange = attributedContent.mutableString.range(of: "[/B]")
        
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(style: .caption1, weight: .bold)]
        attributedContent.addAttributes(attributes, range: NSRange(location: lowerRange.location, length: upperRange.location + upperRange.length - lowerRange.location))
        
        attributedContent.deleteCharacters(in: upperRange)
        attributedContent.deleteCharacters(in: lowerRange)
        return attributedContent
    }
    
    private func createAttributedStringWithTwoBoldTags(content: String) -> NSAttributedString? {
        let attributedContent = NSMutableAttributedString(string: content, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
        let lowerRangeFromStart = attributedContent.mutableString.range(of: "[B]")
        let upperRangeFromStart = attributedContent.mutableString.range(of: "[/B]")
        
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(style: .caption1, weight: .bold)]
        attributedContent.addAttributes(attributes, range: NSRange(location: lowerRangeFromStart.location, length: upperRangeFromStart.location + upperRangeFromStart.length - lowerRangeFromStart.location))
        
        let lowerRangeFromEnd = attributedContent.mutableString.range(of: "[B]", options: .backwards)
        let upperRangeFromEnd = attributedContent.mutableString.range(of: "[/B]", options: .backwards)
        
        attributedContent.addAttributes(attributes, range: NSRange(location: lowerRangeFromEnd.location, length: upperRangeFromEnd.location + upperRangeFromEnd.length - lowerRangeFromEnd.location))
        
        attributedContent.deleteCharacters(in: upperRangeFromEnd)
        attributedContent.deleteCharacters(in: lowerRangeFromEnd)
        
        attributedContent.deleteCharacters(in: upperRangeFromStart)
        attributedContent.deleteCharacters(in: lowerRangeFromStart)
        return attributedContent
    }
    
    private func startAndEndDateString(for scheduledMeeting: ScheduledMeetingEntity) -> (startDateString: String, endDateString: String)? {
        guard let endDate = scheduledMeeting.rules.until else {
            return nil
        }
        
        let startDateString = dateString(for: scheduledMeeting.startDate)
        
        let startTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: scheduledMeeting.startDate)
        let endTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: scheduledMeeting.endDate)
        
        let endDateString = dateString(for: endDate)
        + " • "
        + startTimeString
        + " - "
        + endTimeString
        
        return (startDateString, endDateString)
    }
    
    private func dateString(for scheduledMeeting: ScheduledMeetingEntity) -> String {
        dateString(for: scheduledMeeting.startDate)
        + " • "
        + DateFormatter.fromTemplate("h:mm").localisedString(from: scheduledMeeting.startDate)
        + " - "
        + DateFormatter.fromTemplate("h:mm").localisedString(from: scheduledMeeting.endDate)
    }
    
    private func dateString(for date: Date) -> String {
        DateFormatter.fromTemplate("d MMM").localisedString(from: date)
        + ", "
        + DateFormatter.fromTemplate("yyyy").localisedString(from: date)
    }
    
    private func contentForDailyNewScheduledMeeting(_ scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        let content: String
        if let dateStrings = startAndEndDateString(for: scheduledMeeting) {
            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Ending.New.description(email, dateStrings.startDateString, dateStrings.endDateString)
        } else {
            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Forever.New.description(email, dateString(for: scheduledMeeting))
        }
        
        return createAttributedStringWithOneBoldTag(content: content)
    }
    
    private func contentForWeeklyNewScheduledMeeting(_ scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        var content: String?
        if let dateStrings = startAndEndDateString(for: scheduledMeeting) {
            if let weekDays = scheduledMeeting.rules.weekDayList {
                let weekName = stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? ""
                if weekDays.count == 1 {
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Single.New.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            weekName,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Single.New.description(
                            email,
                            weekName,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    }
                } else if weekDays.count > 1 {
                    let weekdayStringList = weekDays
                        .compactMap {  $0 == weekDays.last ? nil : stringRepresentingWeekDayShortName(forNumber: $0) }
                        .joined(separator: ", ")
                    let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDays[weekDays.count - 1]) ?? ""
                    
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Multiple.New.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            weekdayStringList,
                            lastWeekdayString,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Multiple.New.description(
                            email,
                            weekdayStringList,
                            lastWeekdayString,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    }
                    
                }
            }
        } else {
            if let weekDays = scheduledMeeting.rules.weekDayList {
                if weekDays.count == 1 {
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Single.New.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                            dateString(for: scheduledMeeting)
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Single.New.description(
                            email,
                            stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                            dateString(for: scheduledMeeting)
                        )
                    }
                } else if weekDays.count > 1 {
                    let weekdayStringList = weekDays
                        .compactMap {  $0 == weekDays.last ? nil : stringRepresentingWeekDayShortName(forNumber: $0) }
                        .joined(separator: ", ")
                    let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDays[weekDays.count - 1]) ?? ""
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Multiple.New.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            weekdayStringList,
                            lastWeekdayString,
                            dateString(for: scheduledMeeting)
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Multiple.New.description(
                            email,
                            weekdayStringList,
                            lastWeekdayString,
                            dateString(for: scheduledMeeting)
                        )
                    }
                }
            }
            
        }
        
        guard let content else { return nil }
        return createAttributedStringWithOneBoldTag(content: content)
    }
    
    private func contentForMonthlyNewScheduledMeeting(_ scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        var content: String?
        if let dateStrings = startAndEndDateString(for: scheduledMeeting) {
            if let monthWeekDayList = scheduledMeeting.rules.monthWeekDayList,
               let specificWeek = monthWeekDayList.first?.first,
               let specificWeekDay = monthWeekDayList.first?.last {
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Ending.New.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        "\(scheduledMeeting.rules.interval)",
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Ending.New.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                }
                
            } else if let day = scheduledMeeting.rules.monthDayList?.first {
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Ending.New.description(
                        email,
                        "\(day)",
                        scheduledMeeting.rules.interval,
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                    
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Ending.New.description(
                        email,
                        "\(day)",
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                }
            }
        } else {
            if let monthWeekDayList = scheduledMeeting.rules.monthWeekDayList,
               let specificWeek = monthWeekDayList.first?.first,
               let specificWeekDay = monthWeekDayList.first?.last {
                
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Forever.New.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        "\(scheduledMeeting.rules.interval)",
                        dateString(for: scheduledMeeting)
                    )
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Forever.New.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        dateString(for: scheduledMeeting)
                    )
                }
                
            } else if let day = scheduledMeeting.rules.monthDayList?.first {
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Forever.New.description(
                        email,
                        "\(day)",
                        scheduledMeeting.rules.interval,
                        dateString(for: scheduledMeeting)
                    )
                    
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Forever.New.description(
                        email,
                        "\(day)",
                        dateString(for: scheduledMeeting)
                    )
                }
            }
        }
        
        guard let content else { return nil }
        return createAttributedStringWithOneBoldTag(content: content)
    }
    
    private func contentForScheduledMeetingTitleUpdate(
        withScheduleMeetingId meetingId: ChatIdEntity,
        chatId: ChatIdEntity,
        email: String,
        oldTitle: String?,
        newTitle: String?,
        isReccurring: Bool
    ) -> NSAttributedString? {
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: meetingId, chatId: chatId
        )?.toScheduledMeetingEntity() else {
            return nil
        }
        
        var scheduleMeetingDateString = DateFormatter.fromTemplate("E").localisedString(from: scheduledMeeting.startDate)
        + ", "
        + dateString(for: scheduledMeeting)
        
        let previousTitle = oldTitle ?? ""
        let updatedTitle = newTitle ?? scheduledMeeting.title
        let content: String
        
        if isReccurring {
            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.TitleUpdate.description(email, previousTitle, updatedTitle)
        } else {
            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.TitleUpdate.description(email, previousTitle, updatedTitle, scheduleMeetingDateString)
        }
        
       return createAttributedStringWithTwoBoldTags(content: content)
    }
    
    func contentForOneOffScheduledMeetingWithMultipleFieldsChanged(scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        return contentForScheduledMeetingWithTwoPlaceholders(
            scheduledMeeting,
            email: email,
            localizedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.MulitpleFieldsUpdate.description
        )
    }
    
    private func contentForDailyScheduledMeetingWithMultipleFieldsChanged(scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        let content: String
        if let dateStrings = startAndEndDateString(for: scheduledMeeting) {
            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Ending.MulitpleFieldsUpdate.description(email, dateStrings.startDateString, dateStrings.endDateString)
        } else {
            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Forever.MulitpleFieldsUpdate.description(email, dateString(for: scheduledMeeting))
        }
        
        return createAttributedStringWithOneBoldTag(content: content)
    }
    
    private func contentForWeeklyScheduledMeetingWithMultipleFieldsChanged(scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        var content: String?
        if let dateStrings = startAndEndDateString(for: scheduledMeeting) {
            if let weekDays = scheduledMeeting.rules.weekDayList {
                let weekName = stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? ""
                if weekDays.count == 1 {
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Single.MulitpleFieldsUpdate.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            weekName,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Single.MulitpleFieldsUpdate.description(
                            email,
                            weekName,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    }
                } else if weekDays.count > 1 {
                    let weekdayStringList = weekDays
                        .compactMap {  $0 == weekDays.last ? nil : stringRepresentingWeekDayShortName(forNumber: $0) }
                        .joined(separator: ", ")
                    let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDays[weekDays.count - 1]) ?? ""
                    
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Multiple.MulitpleFieldsUpdate.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            weekdayStringList,
                            lastWeekdayString,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Multiple.MulitpleFieldsUpdate.description(
                            email,
                            weekdayStringList,
                            lastWeekdayString,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    }
                    
                }
            }
        } else {
            if let weekDays = scheduledMeeting.rules.weekDayList {
                if weekDays.count == 1 {
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Single.MulitpleFieldsUpdate.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                            dateString(for: scheduledMeeting)
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Single.MulitpleFieldsUpdate.description(
                            email,
                            stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                            dateString(for: scheduledMeeting)
                        )
                    }
                } else if weekDays.count > 1 {
                    let weekdayStringList = weekDays
                        .compactMap {  $0 == weekDays.last ? nil : stringRepresentingWeekDayShortName(forNumber: $0) }
                        .joined(separator: ", ")
                    let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDays[weekDays.count - 1]) ?? ""
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Multiple.MulitpleFieldsUpdate.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            weekdayStringList,
                            lastWeekdayString,
                            dateString(for: scheduledMeeting)
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Multiple.MulitpleFieldsUpdate.description(
                            email,
                            weekdayStringList,
                            lastWeekdayString,
                            dateString(for: scheduledMeeting)
                        )
                    }
                }
            }
            
        }
        
        guard let content else { return nil }
        return createAttributedStringWithOneBoldTag(content: content)
    }
    
    private func contentForMonthlyScheduledMeetingWithMultipleFieldsChanged(scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        var content: String?
        if let dateStrings = startAndEndDateString(for: scheduledMeeting) {
            if let monthWeekDayList = scheduledMeeting.rules.monthWeekDayList,
               let specificWeek = monthWeekDayList.first?.first,
               let specificWeekDay = monthWeekDayList.first?.last {
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Ending.MulitpleFieldsUpdate.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        "\(scheduledMeeting.rules.interval)",
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Ending.MulitpleFieldsUpdate.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                }
                
            } else if let day = scheduledMeeting.rules.monthDayList?.first {
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Ending.MulitpleFieldsUpdate.description(
                        email,
                        "\(day)",
                        scheduledMeeting.rules.interval,
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                    
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Ending.MulitpleFieldsUpdate.description(
                        email,
                        "\(day)",
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                }
            }
        } else {
            if let monthWeekDayList = scheduledMeeting.rules.monthWeekDayList,
               let specificWeek = monthWeekDayList.first?.last,
               let specificWeekDay = monthWeekDayList.first?.first {
                
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Forever.MulitpleFieldsUpdate.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        "\(scheduledMeeting.rules.interval)",
                        dateString(for: scheduledMeeting)
                    )
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Forever.MulitpleFieldsUpdate.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        dateString(for: scheduledMeeting)
                    )
                }
                
            } else if let day = scheduledMeeting.rules.monthDayList?.first {
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Forever.MulitpleFieldsUpdate.description(
                        email,
                        "\(day)",
                        scheduledMeeting.rules.interval,
                        dateString(for: scheduledMeeting)
                    )
                    
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Forever.MulitpleFieldsUpdate.description(
                        email,
                        "\(day)",
                        dateString(for: scheduledMeeting)
                    )
                }
            }
        }
        
        guard let content else { return nil }
        return createAttributedStringWithOneBoldTag(content: content)
    }
    
    private func contentForOneOffScheduledMeetingWithDescriptionFieldChanged(scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        return contentForScheduledMeetingWithTwoPlaceholders(
            scheduledMeeting,
            email: email,
            localizedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.DescriptionFieldUpdate.description
        )
    }
    
    private func contentForDailyScheduledMeetingWithDescriptionFieldChanged(scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        let content: String
        if let dateStrings = startAndEndDateString(for: scheduledMeeting) {
            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Ending.DescriptionFieldUpdate.description(email, dateStrings.startDateString, dateStrings.endDateString)
        } else {
            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Forever.DescriptionFieldUpdate.description(email, dateString(for: scheduledMeeting))
        }
        
        return createAttributedStringWithOneBoldTag(content: content)
    }
    
    private func contentForWeeklyScheduledMeetingWithDescriptionFieldChanged(scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        var content: String?
        if let dateStrings = startAndEndDateString(for: scheduledMeeting) {
            if let weekDays = scheduledMeeting.rules.weekDayList {
                let weekName = stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? ""
                if weekDays.count == 1 {
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Single.DescriptionFieldUpdate.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            weekName,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Single.DescriptionFieldUpdate.description(
                            email,
                            weekName,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    }
                } else if weekDays.count > 1 {
                    let weekdayStringList = weekDays
                        .compactMap {  $0 == weekDays.last ? nil : stringRepresentingWeekDayShortName(forNumber: $0) }
                        .joined(separator: ", ")
                    let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDays[weekDays.count - 1]) ?? ""
                    
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Multiple.DescriptionFieldUpdate.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            weekdayStringList,
                            lastWeekdayString,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Multiple.DescriptionFieldUpdate.description(
                            email,
                            weekdayStringList,
                            lastWeekdayString,
                            dateStrings.startDateString,
                            dateStrings.endDateString
                        )
                    }
                    
                }
            }
        } else {
            if let weekDays = scheduledMeeting.rules.weekDayList {
                if weekDays.count == 1 {
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Single.DescriptionFieldUpdate.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                            dateString(for: scheduledMeeting)
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Single.DescriptionFieldUpdate.description(
                            email,
                            stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                            dateString(for: scheduledMeeting)
                        )
                    }
                } else if weekDays.count > 1 {
                    let weekdayStringList = weekDays
                        .compactMap {  $0 == weekDays.last ? nil : stringRepresentingWeekDayShortName(forNumber: $0) }
                        .joined(separator: ", ")
                    let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDays[weekDays.count - 1]) ?? ""
                    if scheduledMeeting.rules.interval > 0 {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Multiple.DescriptionFieldUpdate.description(
                            email,
                            "\(scheduledMeeting.rules.interval)",
                            weekdayStringList,
                            lastWeekdayString,
                            dateString(for: scheduledMeeting)
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Multiple.DescriptionFieldUpdate.description(
                            email,
                            weekdayStringList,
                            lastWeekdayString,
                            dateString(for: scheduledMeeting)
                        )
                    }
                }
            }
            
        }
        
        guard let content else { return nil }
        return createAttributedStringWithOneBoldTag(content: content)
    }
    
    private func contentForMonthlyScheduledMeetingWithDescriptionFieldChanged(scheduledMeeting: ScheduledMeetingEntity, email: String) -> NSAttributedString? {
        var content: String?
        if let dateStrings = startAndEndDateString(for: scheduledMeeting) {
             if let monthWeekDayList = scheduledMeeting.rules.monthWeekDayList,
               let specificWeek = monthWeekDayList.first?.first,
               let specificWeekDay = monthWeekDayList.first?.last {
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Ending.DescriptionFieldUpdate.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        "\(scheduledMeeting.rules.interval)",
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Ending.DescriptionFieldUpdate.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                }
                
            } else if let day = scheduledMeeting.rules.monthDayList?.first {
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Ending.DescriptionFieldUpdate.description(
                        email,
                        "\(day)",
                        scheduledMeeting.rules.interval,
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                    
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Ending.DescriptionFieldUpdate.description(
                        email,
                        "\(day)",
                        dateStrings.startDateString,
                        dateStrings.endDateString
                    )
                }
            }
        } else {
            if let monthWeekDayList = scheduledMeeting.rules.monthWeekDayList,
               let specificWeek = monthWeekDayList.first?.last,
               let specificWeekDay = monthWeekDayList.first?.first {
                
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Forever.DescriptionFieldUpdate.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        "\(scheduledMeeting.rules.interval)",
                        dateString(for: scheduledMeeting)
                    )
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Forever.DescriptionFieldUpdate.description(
                        email,
                        stringRepresentingWeek(forNumber: specificWeek) ?? "",
                        stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                        dateString(for: scheduledMeeting)
                    )
                }
                
            } else if let day = scheduledMeeting.rules.monthDayList?.first {
                if scheduledMeeting.rules.interval > 1 {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Forever.DescriptionFieldUpdate.description(
                        email,
                        "\(day)",
                        scheduledMeeting.rules.interval,
                        dateString(for: scheduledMeeting)
                    )
                    
                } else {
                    content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Forever.DescriptionFieldUpdate.description(
                        email,
                        "\(day)",
                        dateString(for: scheduledMeeting)
                    )
                }
            }
        }
        
        guard let content else { return nil }
        return createAttributedStringWithOneBoldTag(content: content)
    }
    
    private func contentForOneOffScheduledMeetingWithDateFieldChanged(for alert: MEGAUserAlert) -> NSAttributedString? {
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return NSAttributedString(string: alert.title)
        }
        
        let startDateList = alert.startDateList
        let startDateOriginal = startDateList?.first
        let startDateUpdated = startDateList?.count == 2 ? startDateList?.last : nil
        
        let endDateList = alert.endDateList
        let endDateOriginal = endDateList?.first
        let endDateUpdated = endDateList?.count == 2 ? endDateList?.last : nil
        
        let startDate = (startDateUpdated ?? startDateOriginal) ?? scheduledMeeting.startDate
        let endDate = ((endDateUpdated ?? endDateOriginal) ?? scheduledMeeting.endDate)

        let startDateString = DateFormatter.fromTemplate("E").localisedString(from: startDate)
        + ", "
        + dateString(for: startDate)
        
        let startTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: startDate)
        let endTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: endDate)

        if let startDateOriginal, startDateUpdated != nil {
            let startDateOriginalString = DateFormatter.fromTemplate("E").localisedString(from: startDateOriginal)
            + ", "
            + dateString(for: startDateOriginal)
            
            if startDateString != startDateOriginalString {
                let content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.DayChanged.description(
                    alert.email ?? "",
                    startDateString,
                    "• " + startTimeString + " - " + endTimeString
                )
                
                return createAttributedStringWithTwoBoldTags(content: content)
            }
        }
        
        let content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.TimeChanged.description(
            alert.email ?? "",
            startDateString + " •",
            startTimeString + " - " + endTimeString
        )
        return createAttributedStringWithTwoBoldTags(content: content)
    }
    
    private func contentForDailyScheduledMeetingWithDateFieldChanged(for alert: MEGAUserAlert) -> NSAttributedString? {
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return NSAttributedString(string: alert.title)
        }

        let startDateList = alert.startDateList
        let startDateOriginal = startDateList?.first
        let startDateUpdated = startDateList?.count == 2 ? startDateList?.last : nil
        
        let endDateList = alert.endDateList
        let endDateOriginal = endDateList?.first
        let endDateUpdated = endDateList?.count == 2 ? endDateList?.last : nil
        
        let startDate = ((startDateUpdated ?? startDateOriginal) ?? scheduledMeeting.startDate)
        let endTime = ((endDateUpdated ?? endDateOriginal) ?? scheduledMeeting.endDate)
        let endDate = scheduledMeeting.rules.until ?? endTime

        let startDateString = dateString(for: startDate)
        let endDateString = dateString(for: endDate)

        let startTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: startDate)
        let endTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: endTime)
        
        let content: String
        if scheduledMeeting.rules.until != nil {
            if isTimeChanged(forAlert: alert) {
                content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Ending.TimeChanged.description(
                    alert.email ?? "",
                    startDateString,
                    endDateString + " •",
                    startTimeString + " - " + endTimeString
                )

            } else {
                content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Ending.DayChanged.description(
                    alert.email ?? "",
                    startDateString,
                    endDateString,
                    "• " + startTimeString + " - " + endTimeString
                )
            }
        } else {
            if isTimeChanged(forAlert: alert) {
                content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Forever.TimeChanged.description(
                    alert.email ?? "",
                    startDateString + " •",
                    startTimeString + " - " + endTimeString
                )
            } else {
                content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Daily.Forever.DayChanged.description(
                    alert.email ?? "",
                    startDateString,
                    "•" + startTimeString + " - " + endTimeString
                )
            }
        }
        
        return createAttributedStringWithTwoBoldTags(content: content)
    }
    
    private func contentForWeeklyScheduledMeetingWithDateFieldChanged(for alert: MEGAUserAlert) -> NSAttributedString? {
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return NSAttributedString(string: alert.title)
        }
        
        let startDateList = alert.startDateList
        let startDateOriginal = startDateList?.first
        let startDateUpdated = startDateList?.count == 2 ? startDateList?.last : nil
        
        let endDateList = alert.endDateList
        let endDateOriginal = endDateList?.first
        let endDateUpdated = endDateList?.count == 2 ? endDateList?.last : nil
        
        let startDate = ((startDateUpdated ?? startDateOriginal) ?? scheduledMeeting.startDate)
        let endTime = ((endDateUpdated ?? endDateOriginal) ?? scheduledMeeting.endDate)
        let endDate = scheduledMeeting.rules.until ?? endTime

        let startDateString = dateString(for: startDate)
        let endDateString = dateString(for: endDate)

        let startTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: startDate)
        let endTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: endTime)
        
        var content: String?
        if scheduledMeeting.rules.until != nil {
            if let weekDays = scheduledMeeting.rules.weekDayList {
                let weekName = stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? ""
                if weekDays.count == 1 {
                    if scheduledMeeting.rules.interval > 0 {
                        if isTimeChanged(forAlert: alert) {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Single.TimeChanged.description(
                                alert.email ?? "",
                                "\(scheduledMeeting.rules.interval)",
                                weekName,
                                startDateString,
                                endDateString + " •",
                                startTimeString + " - " + endTimeString
                            )
                        } else {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Single.DayChanged.description(
                                alert.email ?? "",
                                "\(scheduledMeeting.rules.interval)",
                                weekName,
                                startDateString,
                                endDateString,
                                "• " + startTimeString + " - " + endTimeString
                            )
                        }
                    } else {
                        if isTimeChanged(forAlert: alert) {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Single.TimeChanged.description(
                                alert.email ?? "",
                                weekName,
                                startDateString,
                                endDateString + " •",
                                startTimeString + " - " + endTimeString
                            )
                        } else {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Single.DayChanged.description(
                                alert.email ?? "",
                                weekName,
                                startDateString,
                                endDateString,
                                "• " + startTimeString + " - " + endTimeString
                            )
                        }
                    }
                } else if weekDays.count > 1 {
                    let weekdayStringList = weekDays
                        .compactMap {  $0 == weekDays.last ? nil : stringRepresentingWeekDayShortName(forNumber: $0) }
                        .joined(separator: ", ")
                    let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDays[weekDays.count - 1]) ?? ""
                    
                    if scheduledMeeting.rules.interval > 0 {
                        if isTimeChanged(forAlert: alert) {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Multiple.TimeChanged.description(
                                alert.email ?? "",
                                "\(scheduledMeeting.rules.interval)",
                                weekdayStringList,
                                lastWeekdayString,
                                startDateString,
                                endDateString + " •",
                                startTimeString + " - " + endTimeString
                            )
                        } else {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Ending.Multiple.DayChanged.description(
                                alert.email ?? "",
                                "\(scheduledMeeting.rules.interval)",
                                weekdayStringList,
                                lastWeekdayString,
                                startDateString,
                                endDateString,
                                " •" + startTimeString + " - " + endTimeString
                            )
                        }
                    } else {
                        if isTimeChanged(forAlert: alert) {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Multiple.TimeChanged.description(
                                alert.email ?? "",
                                weekdayStringList,
                                lastWeekdayString,
                                startDateString,
                                endDateString + " •",
                                startTimeString + " - " + endTimeString
                            )
                        } else {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Ending.Multiple.DayChanged.description(
                                alert.email ?? "",
                                weekdayStringList,
                                lastWeekdayString,
                                startDateString,
                                endDateString,
                                "• " + startTimeString + " - " + endTimeString
                            )
                        }
                    }
                }
            }
        } else {
            if let weekDays = scheduledMeeting.rules.weekDayList {
                if weekDays.count == 1 {
                    if scheduledMeeting.rules.interval > 0 {
                        if isTimeChanged(forAlert: alert) {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Single.TimeChanged.description(
                                alert.email ?? "",
                                "\(scheduledMeeting.rules.interval)",
                                stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                                startDateString + " •",
                                startTimeString + " - " + endTimeString
                            )
                        } else {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Single.DayChanged.description(
                                alert.email ?? "",
                                "\(scheduledMeeting.rules.interval)",
                                stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                                startDateString,
                                "• " + startTimeString + " - " + endTimeString
                            )
                        }
                    } else {
                        if isTimeChanged(forAlert: alert) {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Single.TimeChanged.description(
                                alert.email ?? "",
                                stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                                startDateString + " •",
                                startTimeString + " - " + endTimeString
                            )
                        } else {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Single.DayChanged.description(
                                alert.email ?? "",
                                stringRepresentingWeekDayShortName(forNumber: weekDays[0]) ?? "",
                                startDateString,
                                "• " + startTimeString + " - " + endTimeString
                            )
                        }
                    }
                } else if weekDays.count > 1 {
                    let weekdayStringList = weekDays
                        .compactMap {  $0 == weekDays.last ? nil : stringRepresentingWeekDayShortName(forNumber: $0) }
                        .joined(separator: ", ")
                    let lastWeekdayString = stringRepresentingWeekDayShortName(forNumber: weekDays[weekDays.count - 1]) ?? ""
                    if scheduledMeeting.rules.interval > 0 {
                        if isTimeChanged(forAlert: alert) {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Multiple.TimeChanged.description(
                                alert.email ?? "",
                                "\(scheduledMeeting.rules.interval)",
                                weekdayStringList,
                                lastWeekdayString,
                                startDateString + " •",
                                startTimeString + " - " + endTimeString
                            )
                        } else {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificWeek.Forever.Multiple.DayChanged.description(
                                alert.email ?? "",
                                "\(scheduledMeeting.rules.interval)",
                                weekdayStringList,
                                lastWeekdayString,
                                startDateString,
                                "• " + startTimeString + " - " + endTimeString
                            )
                        }
                    } else {
                        if isTimeChanged(forAlert: alert) {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Multiple.TimeChanged.description(
                                alert.email ?? "",
                                weekdayStringList,
                                lastWeekdayString,
                                startDateString + " •",
                                startTimeString + " - " + endTimeString
                            )
                        } else {
                            content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Weekly.Forever.Multiple.DayChanged.description(
                                alert.email ?? "",
                                weekdayStringList,
                                lastWeekdayString,
                                startDateString,
                                "• " + startTimeString + " - " + endTimeString
                            )

                        }
                    }
                }
            }
            
        }
        
        guard let content else { return nil }
        return createAttributedStringWithTwoBoldTags(content: content)
    }
    
    private func contentForMonthlyScheduledMeetingWithDateFieldChanged(for alert: MEGAUserAlert) -> NSAttributedString? {
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return NSAttributedString(string: alert.title)
        }
        
        let startDateList = alert.startDateList
        let startDateOriginal = startDateList?.first
        let startDateUpdated = startDateList?.count == 2 ? startDateList?.last : nil
        
        let endDateList = alert.endDateList
        let endDateOriginal = endDateList?.first
        let endDateUpdated = endDateList?.count == 2 ? endDateList?.last : nil
        
        let startDate = ((startDateUpdated ?? startDateOriginal) ?? scheduledMeeting.startDate)
        let endTime = ((endDateUpdated ?? endDateOriginal) ?? scheduledMeeting.endDate)
        let endDate = scheduledMeeting.rules.until ?? endTime

        let startDateString = dateString(for: startDate)
        let endDateString = dateString(for: endDate)

        let startTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: startDate)
        let endTimeString = DateFormatter.fromTemplate("h:mm").localisedString(from: endTime)
        
        var content: String?
        if scheduledMeeting.rules.until != nil {
            if let monthWeekDayList = scheduledMeeting.rules.monthWeekDayList,
               let specificWeek = monthWeekDayList.first?.first,
               let specificWeekDay = monthWeekDayList.first?.last {
                if scheduledMeeting.rules.interval > 1 {
                    if isTimeChanged(forAlert: alert) {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Ending.TimeChanged.description(
                            alert.email ?? "",
                            stringRepresentingWeek(forNumber: specificWeek) ?? "",
                            stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                            "\(scheduledMeeting.rules.interval)",
                            startDateString,
                            endDateString + " •",
                            startTimeString + " - " + endTimeString
                        )

                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Ending.DayChanged.description(
                            alert.email ?? "",
                            stringRepresentingWeek(forNumber: specificWeek) ?? "",
                            stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                            "\(scheduledMeeting.rules.interval)",
                            startDateString,
                            endDateString,
                            "• " + startTimeString + " - " + endTimeString
                        )
                    }
                } else {
                    if isTimeChanged(forAlert: alert) {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Ending.TimeChanged.description(
                            alert.email ?? "",
                            stringRepresentingWeek(forNumber: specificWeek) ?? "",
                            stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                            startDateString,
                            endDateString + " •",
                            startTimeString + " - " + endTimeString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Ending.DayChanged.description(
                            alert.email ?? "",
                            stringRepresentingWeek(forNumber: specificWeek) ?? "",
                            stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                            startDateString,
                            endDateString,
                            "• " + startTimeString + " - " + endTimeString
                        )
                    }
                }
                
            } else if let day = scheduledMeeting.rules.monthDayList?.first {
                if scheduledMeeting.rules.interval > 1 {
                    if isTimeChanged(forAlert: alert) {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Ending.TimeChanged.description(
                            alert.email ?? "",
                            "\(day)",
                            scheduledMeeting.rules.interval,
                            startDateString,
                            endDateString + " •",
                            startTimeString + " - " + endTimeString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Ending.DayChanged.description(
                            alert.email ?? "",
                            "\(day)",
                            scheduledMeeting.rules.interval,
                            startDateString,
                            endDateString,
                            "• " + startTimeString + " - " + endTimeString
                        )
                    }
                } else {
                    if isTimeChanged(forAlert: alert) {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Ending.TimeChanged.description(
                            alert.email ?? "",
                            "\(day)",
                            startDateString,
                            endDateString + " •",
                            startTimeString + " - " + endTimeString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Ending.DayChanged.description(
                            alert.email ?? "",
                            "\(day)",
                            startDateString,
                            endDateString,
                            "• " + startTimeString + " - " + endTimeString
                        )
                    }
                }
            }
        } else {
            if let monthWeekDayList = scheduledMeeting.rules.monthWeekDayList,
               let specificWeek = monthWeekDayList.first?.last,
               let specificWeekDay = monthWeekDayList.first?.first {
                
                if scheduledMeeting.rules.interval > 1 {
                    if isTimeChanged(forAlert: alert) {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Forever.TimeChanged.description(
                            alert.email ?? "",
                            stringRepresentingWeek(forNumber: specificWeek) ?? "",
                            stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                            "\(scheduledMeeting.rules.interval)",
                            startDateString + " •",
                            startTimeString + " - " + endTimeString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificWeekDay.Forever.DayChanged.description(
                            alert.email ?? "",
                            stringRepresentingWeek(forNumber: specificWeek) ?? "",
                            stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                            "\(scheduledMeeting.rules.interval)",
                            startDateString,
                            "• " + startTimeString + " - " + endTimeString
                        )
                    }
                    
                } else {
                    if isTimeChanged(forAlert: alert) {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Forever.TimeChanged.description(
                            alert.email ?? "",
                            stringRepresentingWeek(forNumber: specificWeek) ?? "",
                            stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                            startDateString + " •",
                            startTimeString + " - " + endTimeString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificWeekDay.Forever.DayChanged.description(
                            alert.email ?? "",
                            stringRepresentingWeek(forNumber: specificWeek) ?? "",
                            stringRepresentingWeekDayShortName(forNumber: specificWeekDay) ?? "",
                            startDateString,
                            "• " + startTimeString + " - " + endTimeString
                        )
                    }
                }
                
            } else if let day = scheduledMeeting.rules.monthDayList?.first {
                if scheduledMeeting.rules.interval > 1 {
                    if isTimeChanged(forAlert: alert) {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Forever.TimeChanged.description(
                            alert.email ?? "",
                            "\(day)",
                            scheduledMeeting.rules.interval,
                            startDateString + " •",
                            startTimeString + " - " + endTimeString
                        )
                        
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.SpecificMonth.SpecificDay.Forever.DayChanged.description(
                            alert.email ?? "",
                            "\(day)",
                            scheduledMeeting.rules.interval,
                            startDateString,
                            "• " + startTimeString + " - " + endTimeString
                        )
                        
                    }
                    
                } else {
                    if isTimeChanged(forAlert: alert) {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Forever.TimeChanged.description(
                            alert.email ?? "",
                            "\(day)",
                            startDateString + " •",
                            startTimeString + " - " + endTimeString
                        )
                    } else {
                        content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Monthly.SpecificDay.Forever.DayChanged.description(
                            alert.email ?? "",
                            "\(day)",
                            startDateString,
                            "• " + startTimeString + " - " + endTimeString
                        )
                    }
                }
            }
        }
        
        guard let content else { return nil }
        return createAttributedStringWithTwoBoldTags(content: content)
    }
    
    private func isTimeChanged(forAlert alert: MEGAUserAlert) -> Bool {
        let startDateList = alert.startDateList
        let startDateOriginal = startDateList?.first
        let startDateUpdated = startDateList?.count == 2 ? startDateList?.last : nil
        
        let endDateList = alert.endDateList
        let endDateOriginal = endDateList?.first
        let endDateUpdated = endDateList?.count == 2 ? endDateList?.last : nil
        
        let startDateOriginalString: String?
        if let startDateOriginal {
            startDateOriginalString = DateFormatter.fromTemplate("dd/MM/yyyy").localisedString(from: startDateOriginal)
        } else {
            startDateOriginalString = nil
        }
        
        let startDateUpdatedString: String?
        if let startDateUpdated {
            startDateUpdatedString = DateFormatter.fromTemplate("dd/MM/yyyy").localisedString(from: startDateUpdated)
        } else {
            startDateUpdatedString = nil
        }
        
        let endDateOriginalString: String?
        if let endDateOriginal {
            endDateOriginalString = DateFormatter.fromTemplate("dd/MM/yyyy").localisedString(from: endDateOriginal)
        } else {
            endDateOriginalString = nil
        }
        
        let endDateUpdatedString: String?
        if let endDateUpdated {
            endDateUpdatedString = DateFormatter.fromTemplate("dd/MM/yyyy").localisedString(from: endDateUpdated)
        } else {
            endDateUpdatedString = nil
        }
        
        if let startDateUpdatedString, let endDateUpdatedString {
            return startDateOriginalString == startDateUpdatedString && endDateOriginalString == endDateUpdatedString
        } else if let startDateUpdatedString {
            return startDateOriginalString == startDateUpdatedString
        } else if let endDateUpdatedString {
            return endDateOriginalString == endDateUpdatedString
        } else {
            return false
        }
    }
    
    private func checkIfMultipleFieldsHaveChangedForScheduledMeeting(in alert: MEGAUserAlert) -> Bool {
        var counter = 0
        
        if alert.hasScheduledMeetingChangeType(.title) {
            counter += 1
        }
        
        if alert.hasScheduledMeetingChangeType(.cancelled) {
            counter += 1
        }
        
        if alert.hasScheduledMeetingChangeType(.description) {
            counter += 1
        }
        
        if alert.hasScheduledMeetingChangeType(.startDate) || alert.hasScheduledMeetingChangeType(.endDate) {
            counter += 1
        }
        
        if alert.hasScheduledMeetingChangeType(.timeZone) {
            counter += 1
        }
        
        if alert.hasScheduledMeetingChangeType(.rules) {
            counter += 1
        }
        
        return counter > 1
    }
    
    private func stringRepresentingWeek(forNumber number: Int) -> String? {
        switch number {
        case 1: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Week.One.title
        case 2: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Week.Two.title
        case 3: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Week.Three.title
        case 4: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Week.Four.title
        case 5: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Week.Five.title
        default: return nil
        }
    }
    
    private func stringRepresentingWeekDayShortName(forNumber number: Int) -> String? {
        switch number {
        case 1: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Mon.title
        case 2: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Tue.title
        case 3: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Wed.title
        case 4: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Thu.title
        case 5: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Fri.title
        case 6: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Sat.title
        case 7: return Strings.Localizable.Inapp.Notifications.ScheduledMeetings.WeekDay.Sun.title
        default: return nil
        }
    }
}
