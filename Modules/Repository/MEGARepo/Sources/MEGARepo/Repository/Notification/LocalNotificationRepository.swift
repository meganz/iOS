import MEGADomain
@preconcurrency import UserNotifications

public struct LocalNotificationRepository: LocalNotificationRepositoryProtocol {
    private let notificationCenter: UNUserNotificationCenter
    
    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }
    
    public func scheduleNotification(_ notification: LocalNotificationEntity) async throws {
        guard await notificationCenter.notificationSettings().authorizationStatus == .authorized else {
            throw LocalNotificationErrorEntity.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.userInfo = notification.userInfo
        content.sound = .default
        
        let triggerDate = Calendar.current
            .dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: notification.date)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: notification.repeats)
        
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger)
        
        try await notificationCenter.add(request)
    }
    
    public func cancelNotification(with id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [id])
    }
}
