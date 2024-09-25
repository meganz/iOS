import UIKit

@objc public extension UITabBar {
    /// Create a badge for a UITabBarItem at top right corner.
    /// - Parameter value: The text inside the badge. If the value is `nil`, it the remove the badge if it exists before.
    /// - Parameter color: The background color of the badge.
    /// - Parameter index: The index of the UITabBarItem.
    func setBadge(value: String?, color: UIColor, at index: Int) {
        let existingBadge = badge(at: index)
        existingBadge?.removeFromSuperview()
        
        guard let value else { return }
        
        let badge = TabBarBadge(for: index, value: value, color: color)
        addSubview(badge)
        
        if value.count > 1 {
            badge.frame.size.height = max(15, badge.intrinsicContentSize.height + 2)
            badge.frame.size.width = max(badge.frame.width, badge.intrinsicContentSize.width + 10)
        } else {
            let size = max(15, badge.intrinsicContentSize.height + 2)
            badge.frame.size = CGSize(width: size, height: size)
        }
        badge.layer.cornerRadius = 0.5 * badge.frame.height
        
        updateBadgeLayout(at: index)
    }
    
    func updateBadgeLayout(at index: Int) {
        guard let badgeToUpdate = badge(at: index), items != nil else {
            return
        }

        let badgeHeight = badgeToUpdate.frame.height

        let itemHeight = frame.height - safeAreaInsets.bottom

        let isIPhone = UIDevice.current.userInterfaceIdiom == .phone
        let isLandScape = UIDevice.current.orientation.isLandscape || UIScreen.main.bounds.width > UIScreen.main.bounds.height
        let isIPhoneLandscape = isIPhone && isLandScape
        
        let isRightToLeftLayout = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        
        // Used to shift the badge to the left or right side of the icon
        // based on the layout direction
        let badgeLayoutDirectionFactor: Int = isRightToLeftLayout ? -1 : 1
                
        let barItemFrame = frameForTabBarItem(at: index)
        let barIconSize = sizeForTabBarIcon(at: index)
        
        // Adjustment to the spacing between the icon and the badge on iPhone landscape mode
        let spaceFromBarButtonIcon = isIPhoneLandscape ? barIconSize.width * 0.75 : barIconSize.width / 2
        
        let x = (barItemFrame.origin.x + barItemFrame.width / 2) + (spaceFromBarButtonIcon * CGFloat(badgeLayoutDirectionFactor))
        
        let y = (0.5 * itemHeight) - badgeHeight / 2 + (isIPhoneLandscape ? 2.0 : -4.0)
        
        badgeToUpdate.center = CGPoint(
            x: x,
            y: y
        )
    }
    
    private var tabBarButtons: [UIControl] {
        return subviews.compactMap { $0 as? UIControl }
    }
    
    private func frameForTabBarItem(at index: Int) -> CGRect {
        return tabBarButtons[safe: index]?.frame ?? .zero
    }
    
    private func sizeForTabBarIcon(at index: Int) -> CGSize {
        guard let tabBarButton = tabBarButtons[safe: index] else { return .zero }
        
        for imageView in tabBarButton.subviews where imageView is UIImageView {
            return imageView.bounds.size
        }
            
        return .zero
    }
    
    private func badge(at index: Int) -> TabBarBadge? {
        subviews.first { ($0 as? TabBarBadge)?.hasIdentifier(for: index) == true } as? TabBarBadge
    }
}

private class TabBarBadge: UILabel {
    var identifier: String = String(describing: TabBarBadge.self)
    
    private func identifier(for index: Int) -> String {
        return "\(String(describing: TabBarBadge.self))-\(index)"
    }
    
    convenience init(for index: Int, value: String, color: UIColor) {
        self.init()
        identifier = identifier(for: index)
        clipsToBounds = true
        textAlignment = .center
        backgroundColor = color
        textColor = .white
        font = .preferredFont(forTextStyle: .caption2)
        adjustsFontForContentSizeCategory = true
        text = value
    }
    
    func hasIdentifier(for index: Int) -> Bool {
        let has = identifier == identifier(for: index)
        return has
    }
}
