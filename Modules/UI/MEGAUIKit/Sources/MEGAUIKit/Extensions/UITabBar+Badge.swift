import UIKit

@objc public extension UITabBar {
    /// Create a badge for a UITabBarItem at top right corner.
    /// - Parameter value: The text inside the badge. If the value is `nil`, it the remove the badge if it exists before.
    /// - Parameter index: The index of the UITabBarItem.
    func setBadge(value: String?, at index: Int) {
        let existingBadge = badge(at: index)
        existingBadge?.removeFromSuperview()
        
        guard let value else { return }
        
        let badge = TabBarBadge(for: index, value: value)
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
        guard let badgeToUpdate = badge(at: index),
              let tabBarItems = items else {
            return
        }

        let badgeWidth = badgeToUpdate.frame.width
        let badgeHeight = badgeToUpdate.frame.height

        let itemPosition = CGFloat(index + 1)
        let itemWidth = frame.width / CGFloat(tabBarItems.count)
        let itemHeight = frame.height - safeAreaInsets.bottom
        
        var x = (itemWidth * itemPosition) - (0.5 * itemWidth) + badgeWidth / 2 + 8
        let y = (0.5 * itemHeight) - badgeHeight / 2 - 4
        
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            x = frame.width - x
        }
        
        badgeToUpdate.center = CGPoint(
            x: x,
            y: y
        )
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
    
    convenience init(for index: Int, value: String) {
        self.init()
        identifier = identifier(for: index)
        clipsToBounds = true
        textAlignment = .center
        backgroundColor = .red
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
