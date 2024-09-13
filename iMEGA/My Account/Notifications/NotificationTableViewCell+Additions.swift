import MEGADesignToken
import UIKit

extension NotificationTableViewCell {
    @objc func updateAppearance() {
        theNewView?.backgroundColor = TokenColors.Notifications.notificationSuccess
        theNewLabel?.textColor = TokenColors.Text.success
    }
}
