import MEGADomain
import SwiftUI

extension NotificationEntity {
    public func toNotificationItem(isSeen: Bool) -> NotificationItem {
        NotificationItem(
            id: NotificationID(id),
            title: title,
            description: description, 
            isSeen: isSeen,
            imageName: imageName,
            imagePath: imagePath,
            startDate: startDate,
            endDate: endDate
        )
    }
}

extension Array where Element == NotificationEntity {
    public func toNotificationItems(
        withUnreadIDs unreadIDs: [NotificationIDEntity] = [1]
    ) -> [NotificationItem] {
        compactMap {$0.toNotificationItem(isSeen: !unreadIDs.contains($0.id))}
    }
}
