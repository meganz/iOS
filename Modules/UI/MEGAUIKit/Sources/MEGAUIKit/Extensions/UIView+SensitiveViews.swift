import UIKit

public extension Sequence where Element == Optional<UIView> {
    func applySensitiveAlpha(isSensitive: Bool) {
        self.forEach { $0?.alpha = isSensitive ? 0.5 : 1 }
    }
}
