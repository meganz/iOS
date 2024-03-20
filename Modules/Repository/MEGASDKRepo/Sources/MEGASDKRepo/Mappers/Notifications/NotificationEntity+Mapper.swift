import MEGADomain
import MEGASdk

extension MEGANotificationList {
    public func toNotificationEntities() -> [NotificationEntity] {
        guard size > 0 else { return [] }
        return (0..<size).compactMap { notification(at: $0)?.toNotificationEntity() }
    }
}

extension MEGANotification {
    public func toNotificationEntity() -> NotificationEntity {
        NotificationEntity(notification: self)
    }
}

fileprivate extension NotificationEntity {
    init(notification: MEGANotification) {
        self.init(
            id: NotificationIDEntity(notification.identifier),
            title: notification.title ?? "",
            description: notification.description ?? "",
            imageName: notification.imageName,
            imagePath: notification.imagePath,
            iconName: notification.iconName,
            startDate: notification.startDate,
            endDate: notification.endDate,
            shouldShowBanner: notification.shouldShowBanner,
            firstCallToAction: CallToAction(notification.firstCallToAction),
            secondCallToAction: CallToAction(notification.secondCallToAction)
        )
    }
}

fileprivate extension NotificationEntity.CallToAction {
    init?(_ callToAction: [String: String]?) {
        guard let callToAction else { return nil }

        self.init(
            text: callToAction["text"] ?? "",
            link: URL(string: callToAction["link"] ?? "")
        )
    }
}
