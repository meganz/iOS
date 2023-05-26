import UIKit

public extension UILayoutPriority {
    static func + (lhs: UILayoutPriority, rhs: Float) -> UILayoutPriority {
        UILayoutPriority(lhs.rawValue + rhs)
    }
    
    static func - (lhs: UILayoutPriority, rhs: Float) -> UILayoutPriority {
        UILayoutPriority(lhs.rawValue - rhs)
    }
}
