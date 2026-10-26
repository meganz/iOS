import UIKit

public extension UITabBar {
    /// Whether the system prefers a horizontal tab bar for this trait environment.
    /// iPhone Duo can prefer a vertical side bar, which takes no bottom space.
    /// It reports the system preference. A screen that turns vertical bars off still gets `false`.
    var isHorizontal: Bool {
        // Only the iOS 27.1 SDK has `verticalBarEdge`. Swift 6.4 is the first compiler that ships with it.
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            // Use the trait, not the tab bar frame.
            // On the open iPhone Duo the frame of a vertical tab bar covers the whole window.
            return traitCollection.verticalBarEdge == .unspecified
        }
        #endif
        // Vertical tab bars exist only from iOS 27.1.
        return true
    }
}
