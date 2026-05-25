import Foundation

@available(iOS 16.2, *)
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

    public func stopMonitoring() {
        manager?.stopMonitoring()
        manager = nil
    }
}
