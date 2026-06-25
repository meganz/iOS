import MEGADomain
import MEGASdk
import MEGASwift

public struct LastPurgeRepository: LastPurgeRepositoryProtocol {
    public static var newRepo: LastPurgeRepository {
        LastPurgeRepository(
            store: LastPurgeStore.shared,
            sdk: MEGASdk.sharedSdk
        )
    }

    /// Begins listening for the last-purge event. Must be called early (before `fetchNodes`),
    /// since the SDK emits the event once per session during login and does not replay it.
    public static func startMonitoring() {
        LastPurgeStore.shared.startListening()
    }

    private let store: LastPurgeStore
    private let sdk: MEGASdk

    public var lastPurgeSequence: AnyAsyncSequence<LastPurgeEventEntity> {
        store.purgeEventStream
    }

    public func acknowledgeLastPurge(timestamp: Int64) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.setLastPurgeAcknowledgedWithTimestamp(
                timestamp,
                delegate: RequestDelegate { result in
                    switch result {
                    case .success:
                        store.clearCachedEvent()
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            )
        }
    }
}
