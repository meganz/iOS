import Foundation
import MEGADomain
import MEGASwift

public extension NotificationCenter {
    /// A sequence of successful plan purchases, one element per `.accountDidPurchasedPlan`.
    ///
    /// Lives next to the purchasers that post that notification, so the whole contract has one owner.
    /// The sequence never finishes, so a caller iterating it must cancel its task when it is done.
    static func purchaseSuccesses(from center: NotificationCenter = .default) -> AnyAsyncSequence<Void> {
        center
            .notifications(named: .accountDidPurchasedPlan)
            .map { _ in () }
            .eraseToAnyAsyncSequence()
    }
}
