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
                            
            if let occurrence = occurrences.filter({ $0.scheduledId == alert.scheduledMeetingId }).first {
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
        localizedString: (_ p1: Any, _ p2: Any, _ p3: Any, _ p4: Any, _ p5: Any) -> String
    ) -> String {
        localizedString(
            alert.email ?? "",
            DateFormatter.fromTemplate("E").localisedString(from: startDate),
            DateFormatter.dateMedium().localisedString(from: startDate),
            DateFormatter.timeShort().localisedString(from: startDate),
            DateFormatter.timeShort().localisedString(from: endDate)
        )
    }
}
