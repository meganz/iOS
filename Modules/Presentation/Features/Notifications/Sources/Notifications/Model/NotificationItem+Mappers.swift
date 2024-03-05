import MEGADomain
import SwiftUI

extension NotificationEntity {
    public func toNotificationItem() -> NotificationItem {
        NotificationItem(
            id: NotificationID(id),
            title: title,
            description: description,
            imageName: imageName,
            imagePath: imagePath,
            startDate: startDate,
            endDate: endDate
        )
    }
}
