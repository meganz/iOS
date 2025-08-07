import UserNotifications

enum LocalNotificationId: String, CaseIterable {
    case cameraUploadBackupReminder = "local.cameraUploadBackupReminder"
}

extension UNNotification {
    @objc var isLocalNotification: Bool {
        LocalNotificationId.allCases
            .contains(where: { $0.rawValue == self.request.identifier })
    }
}
