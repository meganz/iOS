import MEGADesignToken
import UIKit

extension CloudDriveViewController {
    @objc var pageBackgroundColor: UIColor {
        TokenColors.Background.page
    }

    @objc var invalidTextFieldColor: UIColor {
        TokenColors.Text.error
    }

    @objc var validTextFieldColor: UIColor {
        TokenColors.Text.primary
    }

    @objc var toolBarBackgroundColor: UIColor {
        TokenColors.Background.surface1
    }
}
