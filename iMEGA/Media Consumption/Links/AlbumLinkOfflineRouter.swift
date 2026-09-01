import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import MEGASdk
import UIKit

@MainActor
protocol AlbumLinkOfflineRouting {
    func copyToOffline(photos: [NodeEntity]) async
}

/// Sends an album link's photos to the Offline section.
///
/// An ordinary cancellable download in every respect but where its nodes come from: the photos come from a
/// public set preview and so belong to neither the account tree nor the folder link SDK, which is
/// everywhere the download would otherwise know to look. Fetching one from the preview suspends, and the
/// transfers are started synchronously, so they are resolved here and handed over already resolved --
/// which is how the album's Save to MEGA has always fed the copy it runs.
struct AlbumLinkOfflineRouter: AlbumLinkOfflineRouting {
    private let nodeProvider: any MEGANodeProviderProtocol
    private let storageChecker: any DeviceStorageChecking
    private let notEnoughStorageAlertRouter: (any NotEnoughStorageAlertRouting)?
    
    init(
        nodeProvider: any MEGANodeProviderProtocol = PublicAlbumNodeProvider.shared,
        storageChecker: some DeviceStorageChecking = DeviceStorageChecker(
            deviceStorageUseCase: DeviceStorageUseCase(deviceStorageRepository: DeviceStorageRepository.newRepo)
        ),
        notEnoughStorageAlertRouter: (any NotEnoughStorageAlertRouting)? = nil
    ) {
        self.nodeProvider = nodeProvider
        self.storageChecker = storageChecker
        self.notEnoughStorageAlertRouter = notEnoughStorageAlertRouter
    }
    
    func copyToOffline(photos: [NodeEntity]) async {
        guard await confirmEnoughStorage(for: photos) else { return }
        
        let preresolvedNodes = await resolveNodes(of: photos)
        
        // Resolving a whole album is slow enough that its screen can be gone by the time it finishes, and
        // the transfer presents from whatever is visible then -- a cancel alert over an unrelated screen.
        guard !Task.isCancelled else { return }
        
        // A photo that failed to resolve keeps its transfer rather than being dropped from the list: a
        // download that quietly brings back fewer photos than were asked for is worse than one that says
        // which of them it could not fetch.
        let transfers = photos.map {
            CancellableTransfer(
                handle: $0.handle,
                nodeEntity: $0,
                name: $0.name,
                appData: nil,
                priority: false,
                isFile: $0.isFile,
                type: .download
            )
        }
        
        CancellableTransferRouter(
            presenter: UIApplication.mnz_visibleViewController(),
            transfers: transfers,
            transferType: .download,
            preresolvedNodes: preresolvedNodes
        ).start()
    }
    
    private func confirmEnoughStorage(for photos: [NodeEntity]) async -> Bool {
        let bytes = photos.reduce(UInt64.zero) { $0 + $1.size }
        
        switch await storageChecker.verdict(forAdditionalBytes: bytes) {
        case .fits:
            return true
        case let .doesNotFit(requiredBytes, availableBytes):
            let alertRouter = notEnoughStorageAlertRouter
                ?? NotEnoughStorageAlertRouter(presenter: UIApplication.mnz_visibleViewController())
            alertRouter.showNotEnoughStorage(requiredBytes: requiredBytes, availableBytes: availableBytes)
            return false
        }
    }
    
    /// Concurrently, because a photo the preview has not cached costs a request of its own and a selection
    /// resolved one at a time would keep the screen waiting for the sum of them. In a window rather than
    /// all at once, because the selection can be the whole album.
    private func resolveNodes(of photos: [NodeEntity]) async -> [HandleEntity: MEGANode] {
        let nodeProvider = nodeProvider
        
        return await withTaskGroup(of: (HandleEntity, MEGANode?).self) { group in
            var resolvedNodes = [HandleEntity: MEGANode]()
            var nextIndex = min(Constants.maxConcurrentResolutions, photos.count)
            
            for photo in photos.prefix(nextIndex) {
                _ = group.addTaskUnlessCancelled { (photo.handle, await nodeProvider.node(for: photo.handle)) }
            }
            
            while let (handle, node) = await group.next() {
                if let node {
                    resolvedNodes[handle] = node
                }
                
                guard nextIndex < photos.count else { continue }
                let photo = photos[nextIndex]
                nextIndex += 1
                _ = group.addTaskUnlessCancelled { (photo.handle, await nodeProvider.node(for: photo.handle)) }
            }
            
            return resolvedNodes
        }
    }
}

private extension AlbumLinkOfflineRouter {
    enum Constants {
        static let maxConcurrentResolutions = 5
    }
}
