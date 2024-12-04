import MEGASwift
import UIKit

extension UIBarButtonItem: @retroactive Matchable {
    nonisolated public static func ~~ (lhs: UIBarButtonItem, rhs: UIBarButtonItem) -> Bool {
        MainActor.assumeIsolated {
            var status = true
            status = status && lhs.title == rhs.title && lhs.image ~~ rhs.image && lhs.style == rhs.style
            status = status && lhs.menu ~~ rhs.menu
            return status
        }
    }
}
