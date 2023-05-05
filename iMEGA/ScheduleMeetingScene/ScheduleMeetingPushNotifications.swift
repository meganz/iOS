
struct ScheduleMeetingPushNotifications {
    static let startsNowCategoryIdentifier = "nz.mega.startsNowScheduledMeeting.message"
    static let startsInFifteenMinutesCategoryIdentifier = "nz.mega.startsInFifteenMinutesScheduledMeeting.message"

    private enum Action: String {
        case join
        case message
        
        var localizedString: String {
            switch self {
            case .join:
                return Strings.Localizable.Meetings.ScheduleMeeting.Notification.MeetingStarts.Button.join
            case .message:
                return Strings.Localizable.Meetings.ScheduleMeeting.Notification.MeetingStarts.Button.message
            }
        }
    }
    
    private init() {}

    static func registerCustomActions() {
        let joinAction = UNNotificationAction(
            identifier: Action.join.rawValue,
            title: Action.join.localizedString,
            options: [.foreground]
        )
        
        let messageAction = UNNotificationAction(
            identifier: Action.message.rawValue,
            title: Action.message.localizedString,
            options: [.foreground]
        )

        let startScheduledMeetingCategory = UNNotificationCategory(
            identifier: ScheduleMeetingPushNotifications.startsNowCategoryIdentifier,
            actions: [joinAction, messageAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([startScheduledMeetingCategory])
    }
    
    static func isScheduleMeeting(response: UNNotificationResponse) -> Bool {
        response.notification.request.content.categoryIdentifier == startsNowCategoryIdentifier
        || response.notification.request.content.categoryIdentifier == startsInFifteenMinutesCategoryIdentifier
    }
    
    static func hasTappedOnJoinAction(forResponse response: UNNotificationResponse) -> Bool {
        response.actionIdentifier == ScheduleMeetingPushNotifications.Action.join.rawValue
    }
}
