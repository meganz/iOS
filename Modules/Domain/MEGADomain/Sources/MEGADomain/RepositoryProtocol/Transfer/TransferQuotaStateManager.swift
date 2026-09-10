import Foundation
import MEGASwift

public protocol TransferQuotaStateNotifying: Sendable {
    func notify(state: TransferQuotaStateEntity)
}

public protocol TransferQuotaStateProviding: Sendable {
    var states: AnyAsyncSequence<TransferQuotaStateEntity> { get }
}
