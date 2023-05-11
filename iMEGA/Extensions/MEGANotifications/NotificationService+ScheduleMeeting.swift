
extension NotificationService {
    func processStartScheduledMeetingNotification(withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void, request: UNNotificationRequest) {
        MEGALogDebug("Process start schedule meeting notification")
        
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            MEGALogError("Unable to create a mutable copy of the content")
            return contentHandler(request.content)
        }
        
        guard let megadataDictionary = request.content.userInfo["megadata"] as? [AnyHashable: Any] else {
            MEGALogError("Unable to find megadata in the user info")
            return contentHandler(bestAttemptContent)
        }
        
        guard let notificationInfo = ScheduleMeetingNotificationInfo(dictionary: megadataDictionary) else {
            MEGALogError("Unable to construct ScheduleMeetingNotificationInfo")
            return contentHandler(bestAttemptContent)
        }

        bestAttemptContent.categoryIdentifier = notificationInfo.startTime == .now ? ScheduleMeetingPushNotifications.startsNowCategoryIdentifier : ScheduleMeetingPushNotifications.startsInFifteenMinutesCategoryIdentifier
        bestAttemptContent.title = notificationInfo.title
        bestAttemptContent.summaryArgument = notificationInfo.title
        bestAttemptContent.body = bodyForStartScheduledMeetingNotification(withInfo: notificationInfo)
        bestAttemptContent.sound = UNNotificationSound.default
        bestAttemptContent.userInfo = ["chatId": notificationInfo.chatId]
        bestAttemptContent.threadIdentifier = notificationInfo.chatId
        
        if let sharedUserDefaults = UserDefaults(suiteName: MEGAGroupIdentifier) {
            let badgeCount = sharedUserDefaults.integer(forKey: MEGAApplicationIconBadgeNumber)
            sharedUserDefaults.set(badgeCount + 1, forKey: MEGAApplicationIconBadgeNumber)
            bestAttemptContent.badge = badgeCount + 1 as NSNumber
        }
        
        contentHandler(bestAttemptContent)
    }

    private func bodyForStartScheduledMeetingNotification(withInfo notificationInfo: ScheduleMeetingNotificationInfo) -> String {
        NSLocalizedString(
            notificationInfo.startTime == .now
            ? "meetings.scheduleMeeting.notification.meetingStartsNow.message"
            : "meetings.scheduleMeeting.notification.meetingStartsInFifteenMins.message",
            comment: ""
        )
    }
}
