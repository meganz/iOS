import ChatRepo
import MEGADomain
import MEGAL10n

final class ScheduleMeetingOccurrenceNotification: NSObject {
    // MARK: - Properties.

    let alert: MEGAUserAlert
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private(set) var message: NSAttributedString?
    private(set) var isMessageLoaded = false
    private let createAttributedStringForBoldTags: (String) -> NSAttributedString?
    private let alternateMessage: () -> NSAttributedString?
    
    // MARK: - Initializer.
    
    init(
        alert: MEGAUserAlert,
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = ScheduledMeetingUseCase(
            repository: ScheduledMeetingRepository(chatSDK: .shared)
        ),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = ChatRoomUseCase(
            chatRoomRepo: ChatRoomRepository.newRepo
        ),
        createAttributedStringForBoldTags: @escaping (String) -> NSAttributedString?,
        alternateMessage: @escaping () -> NSAttributedString?
    ) {
        self.alert = alert
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.createAttributedStringForBoldTags = createAttributedStringForBoldTags
        self.alternateMessage = alternateMessage
    }
    
    // MARK: - Interface methods.
    
    func loadMessage() async throws {
        defer { isMessageLoaded = true }
        
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
                    occurrenceUpdatedMessage(
                        withStartDate: scheduledMeeting.startDate,
                        endDate: scheduledMeeting.endDate
                    )
                )
            }
        } else if alert.type == .scheduledMeetingNew {
            message = createAttributedStringForBoldTags(
                occurrenceUpdatedMessage(
                    withStartDate: scheduledMeeting.startDate,
                    endDate: scheduledMeeting.endDate
                )
            )
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
                        occurrenceUpdatedMessage(
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
    
    private func occurrenceUpdatedMessage(withStartDate startDate: Date, endDate: Date) -> String {
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
                
        guard let chatRoomEntity = chatRoomUseCase.chatRoom(forChatId: alert.nodeHandle),
              let scheduledMeeting = scheduledMeetingUseCase.scheduledMeeting(
                for: alert.scheduledMeetingId,
                chatId: alert.nodeHandle
              ) else {
            return content
        }
        
        content += "\n"
        
        let scheduledMeetingDateBuilder = ScheduledMeetingDateBuilder(scheduledMeeting: scheduledMeeting, chatRoom: chatRoomEntity)
        content += scheduledMeetingDateBuilder.buildDateDescriptionString()
        return content
    }
}
