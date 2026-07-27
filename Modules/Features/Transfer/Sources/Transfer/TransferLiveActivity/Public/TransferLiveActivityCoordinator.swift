import Foundation

@MainActor
public final class TransferLiveActivityCoordinator {

    public static let shared = TransferLiveActivityCoordinator()

    private var manager: TransferLiveActivityManager?

    private init() {}

    public func startMonitoring() {
        guard manager == nil,
              let useCase = SharedTransferIndicator.useCase else { return }
        let manager = TransferLiveActivityManager(
            activityProvider: TransferLiveActivityProvider()
        )
        manager.startMonitoring(snapshotPublisher: useCase.snapshotPublisher)
        self.manager = manager
    }
}
