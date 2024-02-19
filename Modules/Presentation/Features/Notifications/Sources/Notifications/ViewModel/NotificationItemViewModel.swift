import MEGADomain
import MEGAPresentation
import UIKit

public struct NotificationItemViewModel {
    let notification: NotificationItem

    public init(notification: NotificationItem) {
        self.notification = notification
    }

    // This is a placeholder for now
    func footerText() -> String {
        switch notification.tag {
        case .promo:
            "Offer expires in 5 days"
        default:
            "\(notification.date ?? Date())"
        }
    }
}
