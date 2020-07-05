import UIKit

extension UINavigationBar {
    
    /// Will set `self` to a translucent (clear) state.
    /// Setting a `UINavigationBar` translucent, need to also setting `backgroundImage` and `shadowImage` with an empty `UIImage`
    func setTranslucent() {
        if #available(iOS 13, *) {
            let app = UINavigationBarAppearance()
            app.configureWithTransparentBackground()
            app.backgroundColor = nil

            standardAppearance = app
            compactAppearance = app
            scrollEdgeAppearance = app

            tintColor = nil
            isTranslucent = true
        } else {
            tintColor = nil
            backgroundColor = nil
            setBackgroundImage(UIImage(), for: .default)
            shadowImage = UIImage()
            isTranslucent = true
        }
    }
}
