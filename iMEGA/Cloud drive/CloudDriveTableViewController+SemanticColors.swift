import MEGADesignToken
import UIKit

extension CloudDriveTableViewController {
    @objc var tableViewSeparatorColor: UIColor {
        TokenColors.Border.strong
    }

    @objc var bucketHeaderViewBackgroundColor: UIColor {
        TokenColors.Background.page
    }

    @objc var bucketHeaderViewTextColor: UIColor {
        TokenColors.Text.secondary
    }
}
