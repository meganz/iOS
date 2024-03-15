import MEGADesignToken
import UIKit

extension CloudDriveViewController {
    @objc var pageBackgroundColor: UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : .systemBackground
    }

    @objc var invalidTextFieldColor: UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Text.error : .systemRed
    }

    @objc var validTextFieldColor: UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : .label
    }

    @objc var toolBarBackgroundColor: UIColor {
        return UIColor.isDesignTokenEnabled() ? TokenColors.Background.surface1 : .mnz_mainBars(for: traitCollection)
    }
}
