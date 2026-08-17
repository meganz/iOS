import Foundation
import MEGASwift

extension NotificationCenter {
    // Sequence of .accountDidPurchasedPlan signal 
    static var purchaseSuccesses: AnyAsyncSequence<Void> {
        NotificationCenter.default
            .notifications(named: .accountDidPurchasedPlan)
            .map { _ in () }
            .eraseToAnyAsyncSequence()
    }
}
