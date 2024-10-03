import MEGAPresentation
import MEGAUIKit

extension UILabel {
    /// Create a 2-line Label to display title and subtitles in a NavigationBar whose color aligns with Design Token colors.
    @objc static func customNavigationBarLabel(title: String, subtitle: String?, traitCollection: UITraitCollection) -> UILabel {
        let titleColor = UIColor.primaryTextColor()
        let subtitleColor = UIColor.mnz_subtitles()
        
        return customNavBarLabel(title: title, subtitle: subtitle, titleColor: titleColor, subtitleColor: subtitleColor)
    }
}
