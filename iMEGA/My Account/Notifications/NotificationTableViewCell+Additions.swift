import MEGADesignToken
import UIKit

extension NotificationTableViewCell {
    @objc func updateAppearance() {
        theNewView?.backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Notifications.notificationSuccess : UIColor.mnz_turquoise(for: traitCollection)
        theNewLabel?.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.success : UIColor.mnz_whiteFFFFFF()
    }
}
