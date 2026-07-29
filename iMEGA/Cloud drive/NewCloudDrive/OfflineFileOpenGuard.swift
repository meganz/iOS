import MEGADomain
import MEGASwift

protocol OfflineFileOpenGuarding: Sendable {
    /// Cheap pre-check, so callers can skip looking the node up while nothing can be blocked.
    var isActive: Bool { get }
    func shouldBlockOpening(_ node: NodeEntity) async -> Bool
}

/// Decides whether opening a tapped node must be blocked because the device is
/// offline and the file has no local copy to open (new offline mode, IOS-12227).
/// Folders stay browsable, and images are exempt while a cached preview exists —
/// the photo browser can still display them.
struct OfflineFileOpenGuard: OfflineFileOpenGuarding {
    private let isNewOfflineModeEnabled: Bool
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol

    init(
        isNewOfflineModeEnabled: Bool,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol
    ) {
        self.isNewOfflineModeEnabled = isNewOfflineModeEnabled
        self.networkMonitorUseCase = networkMonitorUseCase
        self.nodeUseCase = nodeUseCase
        self.thumbnailUseCase = thumbnailUseCase
    }

    var isActive: Bool {
        isNewOfflineModeEnabled && !networkMonitorUseCase.isConnected()
    }

    /// The local-copy lookups hit Core Data and the file system, so they run off the main
    /// thread — `MEGAStore` switches to a background context when called off the main queue.
    func shouldBlockOpening(_ node: NodeEntity) async -> Bool {
        guard isActive, node.isFile else { return false }

        return await Task.detached(priority: .userInitiated) { [nodeUseCase, thumbnailUseCase] in
            guard !nodeUseCase.isDownloaded(nodeHandle: node.handle) else { return false }

            let isImageWithCachedPreview = node.name.fileExtensionGroup.isImage
                && thumbnailUseCase.cachedPreviewOrOriginalPath(for: node) != nil
            return !isImageWithCachedPreview
        }.value
    }
}
