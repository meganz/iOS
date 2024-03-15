import MEGADesignToken
import UIKit

extension CloudDriveTableViewController {
    @objc var tableViewSeparatorColor: UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Border.strong : .mnz_separator(for: traitCollection)
    }

    @objc var bucketHeaderViewBackgroundColor: UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : .mnz_backgroundElevated(traitCollection)
    }

    @objc var bucketHeaderViewTextColor: UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : .mnz_secondaryGray(for: traitCollection)
    }
}
