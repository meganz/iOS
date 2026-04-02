import Foundation
import MEGADomain

protocol TransferIndicatorViewStateMapping: Sendable {
    func map(_ entity: TransferIndicatorEntity) -> TransferIndicatorViewState
}

struct TransferIndicatorViewStateMapper: TransferIndicatorViewStateMapping {
    public init() {}

    /// Converts the domain transfer indicator entity into the visual state consumed
    /// by the transfer indicator view.
    public func map(_ entity: TransferIndicatorEntity) -> TransferIndicatorViewState {
        switch entity {
        case .hidden:
            .initial
        case .inProgress(let progress):
            .inProgress(progress: progress)
        case .paused(let progress):
            .paused(progress: progress)
        case .completed:
            .completed
        case .warning:
            .warning
        case .error:
            .error
        }
    }
}
