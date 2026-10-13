import MEGAAppSDKRepo
import MEGAPickerFileProviderDomain

/// Queues the node updates the SDK reports for as long as the extension runs, once per process. Started by the
/// first enumerator request; a request after it stopped on an error starts it again.
actor NodeUpdatesCoordinator {
    static let shared = NodeUpdatesCoordinator()

    private var queueingTask: Task<Void, Never>?

    func startQueueing(using useCase: some FileProviderNodeUpdatesUseCaseProtocol) {
        guard queueingTask == nil else { return }

        queueingTask = Task {
            do {
                // Starts after fetchNodes: the changes caught up with after it are still reported one by one, and
                // anything missed before is found when a folder is compared.
                try await FileProviderSession.shared.ensureReady()
                MEGALogDebug("[Picker] Queueing node updates")
                try await useCase.queueNodeUpdates()
                MEGALogError("[Picker] Node updates ended")
            } catch {
                MEGALogError("[Picker] Stopped queueing node updates: \(error)")
            }
            queueingTask = nil
        }
    }
}
