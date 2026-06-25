import Combine
import MEGADomain
import MEGASdk
import MEGASwift

final class LastPurgeStore: NSObject, @unchecked Sendable, MEGADelegate {
    static let shared = LastPurgeStore(sdk: .sharedSdk)

    private let sdk: MEGASdk
    @Atomic private var isListening = false

    private let eventSubject = CurrentValueSubject<LastPurgeEventEntity?, Never>(nil)

    private init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
    }

    func startListening() {
        $isListening.mutate { isListening in
            guard !isListening else { return }
            isListening = true
            sdk.add(self)
        }
    }

    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard request.type == .MEGARequestTypeLogout else { return }
        clearCachedEvent()
    }

    func onEvent(_ api: MEGASdk, event: MEGAEvent) {
        guard event.type == .lastPurge else { return }
        guard let purgeTimestamp = event.optionalNumber(forKey: "ts"),
              let reason = event.optionalNumber(forKey: "reason"),
              let lastActiveTimestamp = event.optionalNumber(forKey: "lastActiveTs") else {
            return
        }
        eventSubject.send(
            LastPurgeEventEntity(
                purgeTimestamp: purgeTimestamp.int64Value,
                reason: LastPurgeEventEntity.PurgeReason(code: reason.intValue),
                lastActiveTimestamp: lastActiveTimestamp.int64Value
            )
        )
    }

    func clearCachedEvent() {
        eventSubject.send(nil)
    }

    var purgeEventStream: AnyAsyncSequence<LastPurgeEventEntity> {
        eventSubject
            .compactMap { $0 }
            .values
            .eraseToAnyAsyncSequence()
    }
}
