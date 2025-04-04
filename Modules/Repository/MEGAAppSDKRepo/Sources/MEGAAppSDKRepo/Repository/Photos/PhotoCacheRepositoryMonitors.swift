import MEGADomain
import MEGASdk
import MEGASwift

public protocol PhotoCacheRepositoryMonitorsProtocol: Sendable {
    /// Async sequence yielding updated photos.
    ///  - Returns: `AnyAsyncSequence` that will yield `[NodeEntity]` items until sequence terminated
    var photosUpdatedAsyncSequence: AnyAsyncSequence<[NodeEntity]> { get async }
    
    /// Start monitoring for photo nodes updates that will update local store and yield updates via `photosUpdatedAsyncSequences`
    /// This is monitoring an infinite async sequence
    func monitorPhotoNodeUpdates() async
    
    /// Start monitoring cache invalidation triggers and invalidate cache when triggered
    func monitorCacheInvalidationTriggers() async
}

public struct PhotoCacheRepositoryMonitors: PhotoCacheRepositoryMonitorsProtocol {
    public var photosUpdatedAsyncSequence: AnyAsyncSequence<[NodeEntity]> {
        get async {
            await photosUpdateSequences.make()
        }
    }
    
    private let sdk: MEGASdk
    private let nodeUpdatesProvider: any NodeUpdatesProviderProtocol
    private let photoLocalSource: any PhotoLocalSourceProtocol
    private let cacheInvalidationTrigger: CacheInvalidationTrigger
    
    private let photosUpdateSequences = MulticastAsyncSequence<[NodeEntity]>()
    
    public init(sdk: MEGASdk,
                nodeUpdatesProvider: some NodeUpdatesProviderProtocol,
                photoLocalSource: some PhotoLocalSourceProtocol,
                cacheInvalidationTrigger: CacheInvalidationTrigger) {
        self.sdk = sdk
        self.nodeUpdatesProvider = nodeUpdatesProvider
        self.photoLocalSource = photoLocalSource
        self.cacheInvalidationTrigger = cacheInvalidationTrigger
    }
    
    public func monitorPhotoNodeUpdates() async {
        MEGALogDebug("Monitor photo node updates started")
        for await nodeUpdates in nodeUpdatesProvider.nodeUpdates {
            guard !Task.isCancelled else {
                await photosUpdateSequences.terminateContinuations()
                break
            }
            let updatedPhotos = nodeUpdates.filter(\.fileExtensionGroup.isVisualMedia)
            guard updatedPhotos.isNotEmpty else { continue }
            await updatePhotos(updatedPhotos)
            
            await photosUpdateSequences.yield(element: updatedPhotos)
        }
        MEGALogWarning("Monitor photo node updates stopped")
    }
    
    public func monitorCacheInvalidationTriggers() async {
        guard !Task.isCancelled else {
            return
        }
        MEGALogDebug("Monitor cache invalidation triggers started")
        for await _ in await cacheInvalidationTrigger.cacheInvalidationSequence() {
            guard !Task.isCancelled else {
                break
            }
            await photoLocalSource.removeAllPhotos(forced: true)
            MEGALogWarning("Cache invalidation triggered forced cleared")
        }
        MEGALogWarning("Monitor cache invalidation triggers stopped")
    }
    
    private func updatePhotos(_ updatedPhotos: [NodeEntity]) async {
        let photosToStore = await withTaskGroup(of: NodeEntity?.self) { group in
            updatedPhotos.forEach { updatedPhoto in
                group.addTask {
                    if !updatedPhoto.changeTypes.contains(.new) {
                        await photoLocalSource.removePhoto(forHandle: updatedPhoto.handle)
                    }
                    
                    guard let photo = sdk.node(forHandle: updatedPhoto.handle),
                          !sdk.isNode(inRubbish: photo) else {
                        return nil
                    }
                    return photo.toNodeEntity()
                }
            }

            return await group.reduce(into: [NodeEntity]()) {
                if let photo = $1 { $0.append(photo) }
            }
        }
        
        guard photosToStore.isNotEmpty else { return }
        await photoLocalSource.setPhotos(photosToStore)
    }
}
