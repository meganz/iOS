import ChatRepo
import MEGADomain
import MEGAL10n
import MEGASwift

final class ScheduleMeetingOccurrenceNotification: NSObject, @unchecked Sendable {
    // MARK: - Properties.

    let alert: MEGAUserAlert
    private let scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let createAttributedStringForBoldTags: (String) -> AttributedString?
    
    @Atomic var message: AttributedString?
    @Atomic var isMessageLoaded = false
    // MARK: - Initializer.
    
    init(
        alert: MEGAUserAlert,
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = ScheduledMeetingUseCase(
            repository: ScheduledMeetingRepository(chatSDK: .shared)
        ),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = ChatRoomUseCase(
            chatRoomRepo: ChatRoomRepository.newRepo
        ),
        createAttributedStringForBoldTags: @escaping (String) -> AttributedString?
    ) {
        self.alert = alert
        self.scheduledMeetingUseCase = scheduledMeetingUseCase
        self.chatRoomUseCase = chatRoomUseCase
        self.createAttributedStringForBoldTags = createAttributedStringForBoldTags
    }
    
    // MARK: - Interface methods.
    
    func loadMessage() async throws {
        defer { $isMessageLoaded.mutate { $0 = true } }
        let newMessage = try await getMessage()
        $message.mutate { $0 = newMessage }
    }
    
    // MARK: - Private methods.
    
    private func getMessage() async throws -> AttributedString? {
        guard let scheduledMeeting = scheduledMeetingUseCase.scheduledMeeting(
            for: alert.scheduledMeetingId,
            chatId: alert.nodeHandle
        ) else {
            throw ScheduleMeetingErrorEntity.scheduledMeetingNotFound
        }
        if scheduledMeeting.cancelled {
            return createAttributedStringForBoldTags(
                occurrenceCancelledMessage(
                    withStartDate: scheduledMeeting.startDate,
                    endDate: scheduledMeeting.endDate
                )
            )
        } else {
            return createAttributedStringForBoldTags(
                occurrenceUpdatedMessage(
                    withStartDate: scheduledMeeting.startDate,
                    endDate: scheduledMeeting.endDate
                )
            )
        }
    }
    
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
                
        guard chatRoomUseCase.chatRoom(forChatId: alert.nodeHandle) != nil,
              let scheduledMeeting = scheduledMeetingUseCase.scheduledMeeting(
                for: alert.scheduledMeetingId,
                chatId: alert.nodeHandle
              ) else {
            return content
        }
        
        content += "\n"
        
        let scheduledMeetingDateBuilder = ScheduledMeetingDateBuilder(scheduledMeeting: scheduledMeeting)
        content += scheduledMeetingDateBuilder.buildDateDescriptionString()
        return content
    }
}
