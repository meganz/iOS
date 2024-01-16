import MEGAPresentation
import MEGAUIKit

extension UILabel {
    /// Create a 2-line Label to display title and subtitles in a NavigationBar whose color aligns with Design Token colors.
    @objc static func customNavigationBarLabel(title: String, subtitle: String?, traitCollection: UITraitCollection) -> UILabel {
        let titleColor = UIColor.mnz_navigationBarTitle(for: traitCollection)
        let subtitleColor = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) ? UIColor.mnz_subtitles(for: traitCollection) : titleColor.withAlphaComponent(0.8)
        
        return customNavBarLabel(title: title, subtitle: subtitle, titleColor: titleColor, subtitleColor: subtitleColor)
    }
}
