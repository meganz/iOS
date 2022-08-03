import UIKit

public extension UINavigationBar {
    
    /// Will set `self` to a translucent (clear) state.
    /// Setting a `UINavigationBar` translucent, need to also setting `backgroundImage` and `shadowImage` with an empty `UIImage`
    func setTranslucent() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        standardAppearance = appearance
        compactAppearance = appearance
        scrollEdgeAppearance = appearance
        
        isTranslucent = true
    }
}
