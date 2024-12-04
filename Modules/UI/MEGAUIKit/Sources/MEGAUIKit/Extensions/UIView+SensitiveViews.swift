import UIKit

public extension [UIView?] {
    @MainActor
    func applySensitiveAlpha(isSensitive: Bool) {
        self.forEach { $0?.alpha = isSensitive ? 0.5 : 1 }
    }
}
