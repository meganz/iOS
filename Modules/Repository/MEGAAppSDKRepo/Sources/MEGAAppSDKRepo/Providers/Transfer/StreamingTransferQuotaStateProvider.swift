import AsyncAlgorithms
import Foundation
import MEGADomain
import MEGASwift

/// What: The transfer quota state the SDK reports when a streaming read starts.
/// How: the `EventEntity.EventType.transferQuotaState` global event, via `onEvent`.
/// Notes:
/// - This is to catch the almost full state. Over quota is handled with `EventEntity.EventType.streamingOverQuota`.
/// - Both SDK instances are merged because, unlike downloads, streaming can occur while logged out.
public struct StreamingTransferQuotaStateProvider: TransferQuotaStateProviding {
    private let eventUpdates: @Sendable () -> AnyAsyncSequence<EventEntity>

    public init() {
        self.init {
            merge(
                MEGAUpdateHandlerManager.shared.eventUpdates,
                MEGAUpdateHandlerManager.sharedFolderLink.eventUpdates
            )
            .eraseToAnyAsyncSequence()
        }
    }

    init(eventUpdates: @escaping @Sendable () -> AnyAsyncSequence<EventEntity>) {
        self.eventUpdates = eventUpdates
    }

    public var states: AnyAsyncSequence<TransferQuotaStateEntity> {
        eventUpdates()
            .filter { $0.type == .transferQuotaState }
            .compactMap { TransferQuotaStateEntity(eventNumber: $0.number) }
            .eraseToAnyAsyncSequence()
    }
}

extension TransferQuotaStateEntity {
    init?(eventNumber: Int) {
        switch eventNumber {
        case 0: self = .green
        case 1: self = .orange
        case 2: self = .red
        default: return nil
        }
    }
}
