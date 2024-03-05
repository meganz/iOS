import MEGADomain
import MEGAL10n
import MEGAPresentation
import UIKit

public struct NotificationItemViewModel {
    let notification: NotificationItem

    public init(notification: NotificationItem) {
        self.notification = notification
    }

    func footerText() -> String? {
        switch notification.tag {
        case .promo:
            guard notification.formattedExpirationDate.isNotEmpty else {
                return nil
            }
            return Strings.Localizable.Notifications.Expiration.message(
                notification.formattedExpirationDate,
                notification.formattedExpirationTime
            )
        default:
            return notification.formattedExpirationDate
        }
    }
}
