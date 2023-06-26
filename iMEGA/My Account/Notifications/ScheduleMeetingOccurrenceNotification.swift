import MEGADomain

final class ScheduleMeetingOccurrenceNotification: NSObject {
    // MARK: - Properties.

    let alert: MEGAUserAlert
    private(set) var message: NSAttributedString?
    private(set) var isMessageLoaded = false
    private let createAttributedStringForBoldTags: (String) -> NSAttributedString?
    private let alternateMessage: () -> NSAttributedString?
    
    // MARK: - Initializer.
    
    init(
        alert: MEGAUserAlert,
        createAttributedStringForBoldTags: @escaping (String) -> NSAttributedString?,
        alternateMessage: @escaping () -> NSAttributedString?
    ) {
        self.alert = alert
        self.createAttributedStringForBoldTags = createAttributedStringForBoldTags
        self.alternateMessage = alternateMessage
    }
    
    // MARK: - Interface methods.
    
    func loadMessage() async throws {
        defer { isMessageLoaded = true }
        let scheduledMeetingUseCase = ScheduledMeetingUseCase(
            repository: ScheduledMeetingRepository(chatSDK: MEGAChatSdk.shared)
        )
        
        guard let scheduledMeeting = scheduledMeetingUseCase.scheduledMeeting(
            for: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        ) else {
            throw ScheduleMeetingErrorEntity.scheduledMeetingNotFound
        }
        
        if alert.type == .scheduledMeetingUpdated {
            if alert.hasScheduledMeetingChangeType(.cancelled) {
                message = createAttributedStringForBoldTags(
                    occurrenceCancelledMessage(
                        withStartDate: scheduledMeeting.startDate,
                        endDate: scheduledMeeting.endDate
                    )
                )
            } else if alert.hasScheduledMeetingChangeType(.startDate)
                        || alert.hasScheduledMeetingChangeType(.endDate) {
                message = createAttributedStringForBoldTags(
                    occcurrenceUpdatedMessage(
                        withStartDate: scheduledMeeting.startDate,
                        endDate: scheduledMeeting.endDate
                    )
                )
            }
            
        } else {
            let occurrences = try? await scheduledMeetingUseCase.scheduledMeetingOccurrencesByChat(chatId: alert.nodeHandle)
                            
            if let occurrence = occurrences?.filter({
                $0.scheduledId == alert.scheduledMeetingId
                && $0.parentScheduledId == alert.pendingContactRequestHandle
                && $0.overrides == alert.number(at: 0)
            }).first {
                if occurrence.cancelled {
                    message = createAttributedStringForBoldTags(
                        occurrenceCancelledMessage(
                            withStartDate: occurrence.startDate,
                            endDate: occurrence.endDate
                        )
                    )
                } else {
                    message = createAttributedStringForBoldTags(
                        occcurrenceUpdatedMessage(
                            withStartDate: occurrence.startDate,
                            endDate: occurrence.endDate
                        )
                    )
                }
            } else if scheduledMeeting.cancelled {
                message = createAttributedStringForBoldTags(
                    occurrenceCancelledMessage(
                        withStartDate: scheduledMeeting.startDate,
                        endDate: scheduledMeeting.endDate
                    )
                )
            } else {
                message = alternateMessage()
            }
        }
    }
    
    // MARK: - Private methods.
    
    private func occurrenceCancelledMessage(withStartDate startDate: Date, endDate: Date) -> String {
        occurrenceMessage(
            withStartDate: startDate,
            endDate: endDate,
            localizedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.OccurrenceCancelled.description
        )
    }
    
    private func occcurrenceUpdatedMessage(withStartDate startDate: Date, endDate: Date) -> String {
        occurrenceMessage(
            withStartDate: startDate,
            endDate: endDate,
            localizedString: Strings.Localizable.Inapp.Notifications.ScheduledMeetings.Recurring.OccurrenceUpdated.description
        )
    }
    
    private func occurrenceMessage(
        withStartDate startDate: Date,
        endDate: Date,
        localizedString: String
    ) -> String {
        var content = localizedString.replacingOccurrences(of: "[Email]", with: alert.email ?? "")

        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo)
        
        let scheduledMeeting: MEGAChatScheduledMeeting? = MEGAChatSdk.shared.scheduledMeeting(alert.nodeHandle, scheduledId: alert.scheduledMeetingId)
        
        guard let chatRoomEntity = chatRoomUseCase.chatRoom(forChatId: alert.nodeHandle),
              let scheduledMeetingEntity = scheduledMeeting?.toScheduledMeetingEntity() else {
            return content
        }
        
        content += "\n"
        
        let scheduledMeetingDateBuilder = ScheduledMeetingDateBuilder(scheduledMeeting: scheduledMeetingEntity, chatRoom: chatRoomEntity)
        content += scheduledMeetingDateBuilder.buildDateDescriptionString()
        return content
    }
}
