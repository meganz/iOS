import Combine
import MEGADomain
import MEGASdk
import MEGASwift

public struct PhotosRepository: PhotosRepositoryProtocol {
    
    private let sdk: MEGASdk
    private let photoLocalSource: any PhotoLocalSourceProtocol
    private let photosRepositoryTaskManager: any PhotosRepositoryTaskManagerProtocol
    private let queue = DispatchQueue(label: "nz.mega.MEGASDKRepo.PhotosRepository")
    
    public init(sdk: MEGASdk,
                photoLocalSource: some PhotoLocalSourceProtocol,
                photosRepositoryTaskManager: some PhotosRepositoryTaskManagerProtocol) {
        self.sdk = sdk
        self.photoLocalSource = photoLocalSource
        self.photosRepositoryTaskManager = photosRepositoryTaskManager
    }
    
    public func photosUpdated() async -> AnyAsyncSequence<[NodeEntity]> {
        await updatePhotoBackgroundMonitoring()
        
        return await photosRepositoryTaskManager.photosUpdatedAsyncSequence
    }
    
    public func allPhotos(excludeSensitive: Bool) async throws -> [NodeEntity] {
        await updatePhotoBackgroundMonitoring()
        
        let photosFromSource = await photoLocalSource.photos
        try Task.checkCancellation()
        if photosFromSource.isNotEmpty {
            return await filterPhotos(
                photosFromSource, excludeSensitive: excludeSensitive)
        }
        let allPhotos = try await loadAllPhotos()
        return await filterPhotos(
            allPhotos, excludeSensitive: excludeSensitive)
    }
    
    public func photo(forHandle handle: HandleEntity, excludeSensitive: Bool) async -> NodeEntity? {
        await updatePhotoBackgroundMonitoring()
        
        return if let photoFromSource = await photoLocalSource.photo(forHandle: handle) {
            if await shouldShowPhoto(photoFromSource, excludeSensitives: excludeSensitive) {
                photoFromSource
            } else {
                nil
            }
        } else {
            try? await allPhotos(excludeSensitive: excludeSensitive)
                .first(where: { $0.handle == handle })
        }
    }
    
    // MARK: Private
    
    /// Load all photos ensure that only single task is running to retrieve the photos from the SDK to avoid multiple calls to the SDK.
    private func loadAllPhotos() async throws -> [NodeEntity] {
        try await photosRepositoryTaskManager.loadAllPhotos {
            return try await searchAllPhotos()
        }
    }
    
    private func searchAllPhotos() async throws -> [NodeEntity] {
        try await [NodeFormatEntity.photo, .video].async
            .map {
                try await searchAllMedia(formatType: $0)
            }
            .reduce([NodeEntity]()) { $0 + $1 }
    }
    
    private func searchAllMedia(formatType: NodeFormatEntity) async throws -> [NodeEntity] {
        let cancelToken = ThreadSafeCancelToken()
        return try await withTaskCancellationHandler {
            try await withAsyncThrowingValue { completion in
                let filter: SearchFilterEntity = .recursive(
                    searchTargetLocation: .folderTarget(.rootNode),
                    supportCancel: true,
                    sortOrderType: .defaultDesc,
                    formatType: formatType,
                    sensitiveFilterOption: .disabled)
                
                let nodeList = sdk.search(with: filter.toMEGASearchFilter(),
                                          orderType: .defaultDesc,
                                          page: nil,
                                          cancelToken: cancelToken.value)
                
                completion(.success(nodeList.toNodeEntities()))
            }
        } onCancel: {
           cancelToken.cancel()
        }
    }
    
    // MARK: Monitoring
    
    /// Unsure that cache is primed and background monitoring is running.
    private func updatePhotoBackgroundMonitoring() async {
        await ensureCacheIsPrimedAfterInvalidation()
        await ensureBackgroundMonitoringIsRunning()
    }
    
    /// Re-prime cache if it was forcefully cleared.
    private func ensureCacheIsPrimedAfterInvalidation() async {
        guard await photoLocalSource.wasForcedCleared else { return }
        if await !didMonitoringTaskStop() {
            await primeCaches()
        }
        await photoLocalSource.clearForcedFlag()
    }
    
    /// Monitor photo node updates and ensure that the tasks are still running in the background.
    /// If a monitor task is stopped all tasks will be stopped and cache will be re-primed and monitoring will be restarted to avoid stale data.
    private func ensureBackgroundMonitoringIsRunning() async {
        guard await didMonitoringTaskStop() else { return }
        
        await photosRepositoryTaskManager.stopBackgroundMonitoring()
        await primeCaches()
        await photosRepositoryTaskManager.startBackgroundMonitoring()
    }
    
    private func primeCaches() async {
        MEGALogDebug("priming cache started")
        await photoLocalSource.removeAllPhotos(forced: false)
        _ = try? await loadAllPhotos()
    }
    
    private func didMonitoringTaskStop() async -> Bool {
        await photosRepositoryTaskManager.didMonitoringTaskStop()
    }
    
    // MARK: Sensitive filtering
    
    private func filterPhotos(_ nodes: [NodeEntity], excludeSensitive: Bool) async -> [NodeEntity] {
        if excludeSensitive {
            await nodes
                .async
                .filter { await shouldShowPhoto($0) }
                .reduce(into: [NodeEntity]()) { $0.append($1) }
        } else {
            nodes
        }
    }
    
    private func shouldShowPhoto(_ node: NodeEntity, excludeSensitives: Bool) async -> Bool {
        if !excludeSensitives {
            true
        } else {
            await shouldShowPhoto(node)
        }
    }
    
    private func shouldShowPhoto(_ node: NodeEntity) async -> Bool {
        if node.isMarkedSensitive {
            false
        } else {
            await withAsyncValue(in: { completion in
                isInheritingSensitivity(
                    node: node, completion: { completion(.success(!$0)) })
            })
        }
    }
    
    private func isInheritingSensitivity(node: NodeEntity, completion: @Sendable @escaping (Bool) -> Void) {
        queue.async {
            if let megaNode = sdk.node(forHandle: node.handle) {
                completion(sdk.isNodeInheritingSensitivity(megaNode))
            } else {
                completion(false)
            }
        }
    }
}
