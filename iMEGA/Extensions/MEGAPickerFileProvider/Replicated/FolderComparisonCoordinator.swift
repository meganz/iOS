import FileProvider
import MEGAAppSDKRepo
import MEGAPickerFileProviderDomain

/// Compares a folder the system asked an enumerator for with its snapshot, once at a time per folder. Opening Files
/// asks for the root's enumerator several times in a row; a request for a folder already being compared is dropped.
actor FolderComparisonCoordinator {
    static let shared = FolderComparisonCoordinator()

    /// How long a comparison waits for the node tree to catch up before it compares without reporting removals.
    private static let nodeTreeTimeout: Duration = .seconds(30)

    private var comparingContainers: Set<NSFileProviderItemIdentifier> = []

    func compareChildren(
        of containerIdentifier: NSFileProviderItemIdentifier,
        using useCase: some FileProviderFolderComparisonUseCaseProtocol
    ) async {
        guard comparingContainers.insert(containerIdentifier).inserted else { return }
        defer { comparingContainers.remove(containerIdentifier) }

        do {
            try await FileProviderSession.shared.ensureReady()
            // Until the node tree has caught up, a child missing from it is not necessarily gone.
            let isNodeTreeCurrent = await FileProviderSession.shared.waitUntilNodeTreeIsCurrent(timeout: Self.nodeTreeTimeout)
            let hasChanges = try await useCase.compareChildren(of: containerIdentifier, reportsRemovals: isNodeTreeCurrent)
            MEGALogDebug("[Picker] Compared \(containerIdentifier.rawValue): changes \(hasChanges), removals reported \(isNodeTreeCurrent)")
        } catch {
            MEGALogError("[Picker] Can't compare \(containerIdentifier.rawValue) with its snapshot: \(error)")
        }
    }
}
