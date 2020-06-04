import UIKit

extension UINavigationBar {
    
    /// Will set `self` to a translucent (clear) state.
    /// Setting a `UINavigationBar` translucent, need to also setting `backgroundImage` and `shadowImage` with an empty `UIImage`
    func setTranslucent() {
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
        isTranslucent = true
    }
}
