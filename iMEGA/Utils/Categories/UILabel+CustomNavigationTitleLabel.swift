import MEGADesignToken
import MEGAPresentation
import MEGAUIKit

extension UILabel {
    /// Create a 2-line Label to display title and subtitles in a NavigationBar whose color aligns with Design Token colors.
    @objc static func customNavigationBarLabel(title: String, subtitle: String?, traitCollection: UITraitCollection) -> UILabel {
        let titleColor = TokenColors.Text.primary
        let subtitleColor = TokenColors.Text.secondary
        
        return customNavBarLabel(title: title, subtitle: subtitle, titleColor: titleColor, subtitleColor: subtitleColor)
    }
}
