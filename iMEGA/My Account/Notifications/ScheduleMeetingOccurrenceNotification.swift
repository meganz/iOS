import MEGADomain

final class ScheduleMeetingOccurrenceNotification: NSObject {
    // MARK: - Properties.

    let alert: MEGAUserAlert
    private(set) var message: String?
    
    // MARK: - Initializer.
    
    init(alert: MEGAUserAlert) {
        self.alert = alert
    }
    
    // MARK: - Interface methods.
    
    func loadMessage() async throws {
        let scheduledMeetingUseCase = ScheduledMeetingUseCase(
            repository: ScheduledMeetingRepository(chatSDK: MEGAChatSdk.shared)
        )
        
        if alert.type == .scheduledMeetingUpdated {
            guard let scheduledMeeting = scheduledMeetingUseCase.scheduledMeeting(
                for: alert.scheduledMeetingId,
                chatId: alert.nodeHandle
            ) else {
                return
            }
            
            if alert.hasScheduledMeetingChangeType(.cancelled) {
                message = occurrenceCancelledMessage(
                    withStartDate: scheduledMeeting.startDate,
                    endDate: scheduledMeeting.endDate
                )
            } else if alert.hasScheduledMeetingChangeType(.startDate)
                        || alert.hasScheduledMeetingChangeType(.endDate) {
                message = occcurrenceUpdatedMessage(
                    withStartDate: scheduledMeeting.startDate,
                    endDate: scheduledMeeting.endDate
                )
            }
            
        } else {
            let occurrences = try await scheduledMeetingUseCase.scheduledMeetingOccurrencesByChat(chatId: alert.nodeHandle)
                            
            if let occurrence = occurrences.filter({
                $0.scheduledId == alert.scheduledMeetingId
                && $0.parentScheduledId == alert.pendingContactRequestHandle
                && $0.overrides == alert.number(at: 0)
            }).first {
                if occurrence.cancelled {
                    message = occurrenceCancelledMessage(
                        withStartDate: occurrence.startDate,
                        endDate: occurrence.endDate
                    )
                } else {
                    message = occcurrenceUpdatedMessage(
                        withStartDate: occurrence.startDate,
                        endDate: occurrence.endDate
                    )
                }
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
