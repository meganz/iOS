import Foundation
import MEGADomain
import MEGASwift

/// What: The transfer quota state the SDK predicts for a batch download.
/// When: batch download. `MEGASdk.startDownloadBatch` only.
/// How: `TransferDelegate.onTransferQuotaState` passed to `MEGASdk.startDownloadBatch`
public final class DownloadTransferQuotaStateProvider: @unchecked Sendable, TransferQuotaStateProviding, TransferQuotaStateNotifying {
    final class TransferQuotaStateChangeHandler: NSObject, Sendable {
        let onStateUpdate: @Sendable (TransferQuotaStateEntity) -> Void
        
        init(onStateUpdate: @escaping @Sendable (TransferQuotaStateEntity) -> Void) {
            self.onStateUpdate = onStateUpdate
        }
    }
    
    @Atomic
    private var handlers: [TransferQuotaStateChangeHandler] = []
    
    public static let shared = DownloadTransferQuotaStateProvider()
    
    // MARK: - TransferQuotaStateProviding
    
    public var states: AnyAsyncSequence<TransferQuotaStateEntity> {
        AsyncStream { continuation in
            let handler = TransferQuotaStateChangeHandler { state in
                continuation.yield(state)
            }
            
            continuation.onTermination = { [weak self] _ in
                self?.remove(handler)
            }
            
            add(handler)
                
        }.eraseToAnyAsyncSequence()
    }
    
    // MARK: - TransferQuotaStateNotifying
    
    public func notify(state: TransferQuotaStateEntity) {
        handlers.forEach {
            $0.onStateUpdate(state)
        }
    }
    
    // MARK: - Privates
    
    private func add(_ handler: TransferQuotaStateChangeHandler) {
        $handlers.mutate { $0.append(handler) }
    }
    
    private func remove(_ handler: TransferQuotaStateChangeHandler) {
        $handlers.mutate { $0.remove(object: handler) }
    }
}
