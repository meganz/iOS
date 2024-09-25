import UIKit

public extension UIViewController {
    
    @objc func forceTabBarPositionToBottomIfNeeded() {
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            traitOverrides.horizontalSizeClass = .compact
        }
    }
    
    /// Resetting custom `traitOverrides` for any size classes values
    func resetsTraitOverridesIfNeeded() {
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            traitOverrides.horizontalSizeClass = traitCollection.horizontalSizeClass
            traitOverrides.verticalSizeClass = traitCollection.verticalSizeClass
        }
    }
}
