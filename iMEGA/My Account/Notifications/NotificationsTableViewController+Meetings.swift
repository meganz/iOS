import ChatRepo
import MEGADomain
import MEGAFoundation
import MEGAL10n
import MEGAUI

extension NotificationsTableViewController {
    
    // MARK: - Interface methods
    @objc func contentForNewScheduledMeeting(withAlert alert: MEGAUserAlert, indexPath: IndexPath) -> NSAttributedString? {
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return nil
        }
        
        if alert.pendingContactRequestHandle != MEGAInvalidHandle {
            return occurrenceContent(for: alert, indexPath: indexPath)
        } else if scheduledMeeting.rules.frequency == .invalid {
            return contentForOneOffNewScheduledMeeting(scheduledMeeting, chatId: alert.nodeHandle, email: alert.email ?? "")
        } else if scheduledMeeting.rules.frequency == .daily
                    || scheduledMeeting.rules.frequency == .weekly
                    || scheduledMeeting.rules.frequency == .monthly {
            return contentForRecurringNewScheduledMeeting(scheduledMeeting, chatId: alert.nodeHandle, email: alert.email ?? "")
        }
        
        return NSAttributedString(string: alert.title ?? "")
    }
    
    @objc func contentForUpdatedScheduledMeeting(
        withAlert alert: MEGAUserAlert,
        indexPath: IndexPath,
        checkForOccurrenceChange: Bool,
        useDefaultMessage: Bool
    ) -> NSAttributedString? {
        guard let scheduledMeetingEntity = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return nil
        }
        
        if alert.pendingContactRequestHandle != MEGAInvalidHandle, checkForOccurrenceChange {
            return occurrenceContent(for: alert, indexPath: indexPath)
        } else if alert.hasScheduledMeetingChangeType(.cancelled) {
            if scheduledMeetingEntity.rules.frequency != .invalid {
                return contentForRecurringCancelledScheduledMeeting(withEmail: alert.email ?? "")
            } else {
                return contentForOneOffCancelledScheduledMeeting(scheduledMeetingEntity, chatId: alert.nodeHandle, email: alert.email ?? "")
            }
        } else if checkIfMultipleFieldsHaveChangedForScheduledMeeting(in: alert)
                    || alert.hasScheduledMeetingChangeType(.timeZone)
                    || alert.hasScheduledMeetingChangeType(.rules) {
            if scheduledMeetingEntity.rules.frequency == .invalid {
                return contentForOneOffScheduledMeetingWithMultipleFieldsChanged(
                    scheduledMeeting: scheduledMeetingEntity,
                    chatId: alert.nodeHandle,
                    email: alert.email ?? ""
                )
            } else if scheduledMeetingEntity.rules.frequency == .daily
                        || scheduledMeetingEntity.rules.frequency == .weekly
                        || scheduledMeetingEntity.rules.frequency == .monthly {
                return contentForRecurringScheduledMeetingWithMultipleFieldsChanged(
                    scheduledMeeting: scheduledMeetingEntity,
                    chatId: alert.nodeHandle,
                    email: alert.email ?? ""
                )
            }
        } else if alert.hasScheduledMeetingChangeType(.title) {
            let titleList = alert.titleList?.toArray() ?? []
            return contentForScheduledMeetingTitleUpdate(
                withScheduleMeetingId: alert.scheduledMeetingId,
                chatId: alert.nodeHandle,
                email: alert.email ?? "",
                oldTitle: titleList.first,
                newTitle: titleList.last,
                isRecurring: scheduledMeetingEntity.rules.frequency != .invalid
            )
        } else if alert.hasScheduledMeetingChangeType(.description) {
            if scheduledMeetingEntity.rules.frequency == .invalid {
                return contentForOneOffScheduledMeetingWithDescriptionFieldChanged(
                    scheduledMeeting: scheduledMeetingEntity,
                    chatId: alert.nodeHandle,
                    email: alert.email ?? "")
            } else if scheduledMeetingEntity.rules.frequency == .daily
                        || scheduledMeetingEntity.rules.frequency == .weekly
                        || scheduledMeetingEntity.rules.frequency == .monthly {
                return contentForRecurringScheduledMeetingWithDescriptionFieldChanged(
                    scheduledMeeting: scheduledMeetingEntity,
                    chatId: alert.nodeHandle,
                    email: alert.email ?? "")
            }
        } else if alert.hasScheduledMeetingChangeType(.startDate) || alert.hasScheduledMeetingChangeType(.endDate) {
            if scheduledMeetingEntity.rules.frequency == .invalid {
                return contentForOneOffScheduledMeetingWithDateFieldChanged(for: alert)
            } else if scheduledMeetingEntity.rules.frequency == .daily
                        || scheduledMeetingEntity.rules.frequency == .weekly
                        || scheduledMeetingEntity.rules.frequency == .monthly {
                return contentForRecurringScheduledMeetingWithDateFieldChanged(for: alert)
            }
        }
        
        return contentForOneOffScheduledMeetingWithMultipleFieldsChanged(scheduledMeeting: scheduledMeetingEntity, chatId: alert.nodeHandle, email: alert.email ?? "")
    }
    
    @objc func scheduledMeeting(withScheduleMeetingId meetingId: ChatIdEntity, chatId: ChatIdEntity) -> MEGAChatScheduledMeeting? {
        MEGAChatSdk.shared.scheduledMeeting(chatId, scheduledId: meetingId)
    }
    
    @objc func openChatRoom(forUserAlert alert: MEGAUserAlert) {
        guard let mainTabBarController = UIApplication.mainTabBarRootViewController() as? MainTabBarController else {
            return
        }
        
        navigationController?.popToRootViewController(animated: false)
        mainTabBarController.openChatRoom(chatId: alert.nodeHandle)
    }
    
    // MARK: - Private methods
    
    private func createAttributedStringForBoldTags(content: String) -> NSAttributedString? {
        let attributedContent = NSMutableAttributedString(string: content, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(style: .caption1, weight: .bold)]

        while attributedContent.mutableString.range(of: "[B]").location != NSNotFound {
            let lowerRange = attributedContent.mutableString.range(of: "[B]")
            let upperRange = attributedContent.mutableString.range(of: "[/B]")
            
            if upperRange.location != NSNotFound {
                let location = lowerRange.location
                let length = upperRange.location + upperRange.length - lowerRange.location
                
                attributedContent.addAttributes(attributes, range: NSRange(location: location, length: length))
                attributedContent.deleteCharacters(in: upperRange)
            }
            
            attributedContent.deleteCharacters(in: lowerRange)
        }
        
        return attributedContent
    }
    
    private func occurrenceContent(for alert: MEGAUserAlert, indexPath: IndexPath) -> NSAttributedString? {
        if let notification = scheduleMeetingOccurrenceNotificationList.filter({ $0.alert.identifier == alert.identifier }).first {
            if let message = notification.message {
                return message.toNSAttributedString()
            } else if notification.isMessageLoaded {
                MEGALogError("Unable to load message for alert with title \(notification.alert.title ?? "")")
                return nil
            } else {
                Task {
                    do {
                        try await notification.loadMessage()
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    } catch {
                        MEGALogDebug("unable to load message for alert \(alert.title ?? "")")
                    }
                }
            }
        } else {
            let notification = ScheduleMeetingOccurrenceNotification(alert: alert) { [weak self] message in
                guard let self else { return nil }
                return createAttributedStringForBoldTags(content: message)?.toSwiftAttributedString()
            }
            
            scheduleMeetingOccurrenceNotificationList.append(notification)

            Task {
                do {
                    try await notification.loadMessage()
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                } catch {
                    MEGALogDebug("unable to load message for alert \(alert.title ?? "")")
                }
            }
        }
        
        return nil
    }
    
    private func alternativeMessage(for alert: MEGAUserAlert, indexPath: IndexPath) -> NSAttributedString? {
        guard let message = contentForUpdatedScheduledMeeting(
            withAlert: alert,
            indexPath: indexPath,
            checkForOccurrenceChange: false,
            useDefaultMessage: false
        ) else {
            guard let scheduledMeetingEntity = scheduledMeeting(
                withScheduleMeetingId: alert.scheduledMeetingId,
                chatId: alert.nodeHandle
            )?.toScheduledMeetingEntity() else {
                return nil
            }
            
            return contentForOneOffScheduledMeetingWithMultipleFieldsChanged(
                scheduledMeeting: scheduledMeetingEntity,
                chatId: alert.nodeHandle,
                email: alert.email ?? ""
            )
        }
        
        return message
    }
    
    private func contentForScheduledMeetingTitleUpdate(
        withScheduleMeetingId meetingId: ChatIdEntity,
        chatId: ChatIdEntity,
        email: String,
        oldTitle: String?,
        newTitle: String?,
        isRecurring: Bool
    ) -> NSAttributedString? {
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: meetingId, chatId: chatId
        )?.toScheduledMeetingEntity() else {
            return nil
        }
                
        var content = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.TitleUpdate.description
            .replacingOccurrences(of: "[Email]", with: email)
            .replacingOccurrences(of: "[PreviousTitle]", with: oldTitle ?? "")
            .replacingOccurrences(of: "[UpdatedTitle]", with: newTitle ?? scheduledMeeting.title)

        if !isRecurring, let dateInfo = dateInfo(for: scheduledMeeting, chatId: chatId, removingFormatter: .all) {
            content += "\n" + dateInfo
        }
        
       return createAttributedStringForBoldTags(content: content)
    }
    
    private func dateInfo(
        for scheduledMeeting: ScheduledMeetingEntity,
        chatId: ChatIdEntity,
        removingFormatter formatter: ScheduledMeetingDateBuilder.Formatter,
        startDate: Date? = nil,
        endDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) -> String? {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        
        guard chatRoomUseCase.chatRoom(forChatId: chatId) != nil else { return nil }
        
        let scheduledMeetingDateBuilder = ScheduledMeetingDateBuilder(scheduledMeeting: scheduledMeeting)
        return scheduledMeetingDateBuilder.buildDateDescriptionString(
            removingFormatter: formatter,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime
        )
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
    
    // MARK: - One Off
    
    private func contentForOneOffScheduledMeeting(
        _ scheduledMeeting: ScheduledMeetingEntity,
        chatId: ChatIdEntity,
        email: String,
        localisedString: String,
        removingFormatter formatter: ScheduledMeetingDateBuilder.Formatter,
        createAttributedStringWithBoldTag: (String) -> NSAttributedString?,
        startDate: Date? = nil,
        endDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) -> NSAttributedString? {
        let description = localisedString.replacingOccurrences(of: "[Email]", with: email)
        let dateInfo = dateInfo(
            for: scheduledMeeting,
            chatId: chatId,
            removingFormatter: formatter,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime
        ) ?? ""
        return createAttributedStringWithBoldTag(description + "\n" + dateInfo)
    }
    
    private func contentForOneOffNewScheduledMeeting(
        _ scheduledMeeting: ScheduledMeetingEntity,
        chatId: ChatIdEntity,
        email: String
    ) -> NSAttributedString? {
        contentForOneOffScheduledMeeting(
            scheduledMeeting,
            chatId: chatId,
            email: email,
            localisedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.New.description,
            removingFormatter: .all,
            createAttributedStringWithBoldTag: createAttributedStringForBoldTags
        )
    }
    
    private func contentForOneOffCancelledScheduledMeeting(
        _ scheduledMeeting: ScheduledMeetingEntity,
        chatId: ChatIdEntity,
        email: String
    ) -> NSAttributedString? {
        contentForOneOffScheduledMeeting(
            scheduledMeeting,
            chatId: chatId,
            email: email,
            localisedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.Cancelled.description,
            removingFormatter: .all,
            createAttributedStringWithBoldTag: createAttributedStringForBoldTags
        )
    }
    
    func contentForOneOffScheduledMeetingWithMultipleFieldsChanged(
        scheduledMeeting: ScheduledMeetingEntity,
        chatId: ChatIdEntity,
        email: String
    ) -> NSAttributedString? {
        contentForOneOffScheduledMeeting(
            scheduledMeeting,
            chatId: chatId,
            email: email,
            localisedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.MulitpleFieldsUpdate.description,
            removingFormatter: .all,
            createAttributedStringWithBoldTag: createAttributedStringForBoldTags
        )
    }
    
    private func contentForOneOffScheduledMeetingWithDescriptionFieldChanged(
        scheduledMeeting: ScheduledMeetingEntity,
        chatId: ChatIdEntity,
        email: String
    ) -> NSAttributedString? {
        contentForOneOffScheduledMeeting(
            scheduledMeeting,
            chatId: chatId,
            email: email,
            localisedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.DescriptionFieldUpdate.description,
            removingFormatter: .all,
            createAttributedStringWithBoldTag: createAttributedStringForBoldTags
        )
    }
    
    private func contentForOneOffScheduledMeetingWithDateFieldChanged(for alert: MEGAUserAlert) -> NSAttributedString? {
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return NSAttributedString(string: alert.title ?? "")
        }
        
        let startDateList = alert.startDateList
        let startDateOriginal = startDateList?.first
        let startDateUpdated = startDateList?.count == 2 ? startDateList?.last : nil
        
        let endDateList = alert.endDateList
        let endDateOriginal = endDateList?.first
        let endDateUpdated = endDateList?.count == 2 ? endDateList?.last : nil
        
        let startDate = (startDateUpdated ?? startDateOriginal) ?? scheduledMeeting.startDate
        let endDate = ((endDateUpdated ?? endDateOriginal) ?? scheduledMeeting.endDate)

        let startDateString = DateFormatter.dateMedium().localisedString(from: startDate)

        if let startDateOriginal, startDateUpdated != nil {
            let startDateOriginalString = DateFormatter.dateMedium().localisedString(from: startDateOriginal)
            
            if startDateString != startDateOriginalString {
                return contentForOneOffScheduledMeeting(
                    scheduledMeeting,
                    chatId: alert.nodeHandle,
                    email: alert.email ?? "",
                    localisedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.DayChanged.description,
                    removingFormatter: .last,
                    createAttributedStringWithBoldTag: createAttributedStringForBoldTags,
                    startDate: startDate,
                    endDate: endDate,
                    startTime: startDate,
                    endTime: endDate
                )
            }
        }
        
        return contentForOneOffScheduledMeeting(
            scheduledMeeting,
            chatId: alert.nodeHandle,
            email: alert.email ?? "",
            localisedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.OneOff.TimeChanged.description,
            removingFormatter: .first,
            createAttributedStringWithBoldTag: createAttributedStringForBoldTags,
            startDate: startDate,
            endDate: endDate,
            startTime: startDate,
            endTime: endDate
        )
    }
    
    // MARK: - Recurring
    
    private func contentForRecurringCancelledScheduledMeeting(withEmail email: String) -> NSAttributedString? {
        createAttributedStringForBoldTags(
            content: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.Cancelled.description.replacingOccurrences(
                of: "[Email]",
                with: email
            )
        )
    }
    
    private func contentForRecurringScheduledMeeting(
        scheduledMeeting: ScheduledMeetingEntity,
        localisedString: String,
        chatId: ChatIdEntity,
        email: String,
        removingFormatter formatter: ScheduledMeetingDateBuilder.Formatter,
        createAttributedStringWithBoldTag: (String) -> NSAttributedString?,
        startDate: Date? = nil,
        endDate: Date? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil
    ) -> NSAttributedString? {
        let content = localisedString.replacingOccurrences(of: "[Email]", with: email)
        let dateInfo = dateInfo(
            for: scheduledMeeting,
            chatId: chatId,
            removingFormatter: formatter,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime
        ) ?? ""
        return createAttributedStringWithBoldTag(content + "\n" + dateInfo)
    }
    
    private func contentForRecurringNewScheduledMeeting(
        _ scheduledMeeting: ScheduledMeetingEntity,
        chatId: ChatIdEntity,
        email: String
    ) -> NSAttributedString? {
        contentForRecurringScheduledMeeting(
            scheduledMeeting: scheduledMeeting,
            localisedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.New.description,
            chatId: chatId,
            email: email,
            removingFormatter: .all,
            createAttributedStringWithBoldTag: createAttributedStringForBoldTags
        )
    }
    
    private func contentForRecurringScheduledMeetingWithMultipleFieldsChanged(
        scheduledMeeting: ScheduledMeetingEntity,
        chatId: ChatIdEntity,
        email: String
    ) -> NSAttributedString? {
        contentForRecurringScheduledMeeting(
            scheduledMeeting: scheduledMeeting,
            localisedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.MulitpleFieldsUpdate.description,
            chatId: chatId,
            email: email,
            removingFormatter: .all,
            createAttributedStringWithBoldTag: createAttributedStringForBoldTags
        )
    }
    
    private func contentForRecurringScheduledMeetingWithDescriptionFieldChanged(
        scheduledMeeting: ScheduledMeetingEntity,
        chatId: ChatIdEntity,
        email: String
    ) -> NSAttributedString? {
        contentForRecurringScheduledMeeting(
            scheduledMeeting: scheduledMeeting,
            localisedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.DescriptionFieldUpdate.description,
            chatId: chatId,
            email: email,
            removingFormatter: .all,
            createAttributedStringWithBoldTag: createAttributedStringForBoldTags
        )
    }
    
    private func contentForRecurringScheduledMeetingWithDateFieldChanged(for alert: MEGAUserAlert) -> NSAttributedString? {
        var localisedString: String
        
        let isTimeChanged = isTimeChanged(forAlert: alert)
        let removeFormatter: ScheduledMeetingDateBuilder.Formatter
        
        if isTimeChanged {
            localisedString = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.TimeChanged.description
            removeFormatter = .first
        } else {
            localisedString = Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.DayChanged.description
            removeFormatter = .last
        }
        
        guard let scheduledMeeting = scheduledMeeting(
            withScheduleMeetingId: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        )?.toScheduledMeetingEntity() else {
            return createAttributedStringForBoldTags(content: description)
        }
        
        let startDateList = alert.startDateList
        let startDateOriginal = startDateList?.first
        let startDateUpdated = startDateList?.count == 2 ? startDateList?.last : nil
        
        let endDateList = alert.endDateList
        let endDateOriginal = endDateList?.first
        let endDateUpdated = endDateList?.count == 2 ? endDateList?.last : nil
        
        let startDate = (startDateUpdated ?? startDateOriginal) ?? scheduledMeeting.startDate
        let endDate = ((endDateUpdated ?? endDateOriginal) ?? scheduledMeeting.endDate)

        return contentForRecurringScheduledMeeting(
            scheduledMeeting: scheduledMeeting,
            localisedString: localisedString,
            chatId: alert.nodeHandle,
            email: alert.email ?? "",
            removingFormatter: removeFormatter,
            createAttributedStringWithBoldTag: createAttributedStringForBoldTags,
            startDate: startDate,
            endDate: endDate,
            startTime: startDate,
            endTime: endDate
        )
    }
}
