import Combine
import MEGADomain
import MEGASdk
import MEGASwift

public actor PhotosRepository: PhotosRepositoryProtocol {
    
    private let sdk: MEGASdk
    private let photoLocalSource: any PhotoLocalSourceProtocol
    private let nodeUpdatesProvider: any NodeUpdatesProviderProtocol
    
    private var searchAllPhotosTask: Task<[NodeEntity], Error>?
    private var monitorNodeUpdatesTask: Task<Void, Error>?
    private var monitorCacheInvalidationTask: Task<Void, Error>?
    private let photosUpdateSequences = MulticastAsyncSequence<[NodeEntity]>()
    
    public init(sdk: MEGASdk,
                photoLocalSource: some PhotoLocalSourceProtocol,
                nodeUpdatesProvider: some NodeUpdatesProviderProtocol,
                cacheInvalidationTrigger: CacheInvalidationTrigger) {
        self.sdk = sdk
        self.photoLocalSource = photoLocalSource
        self.nodeUpdatesProvider = nodeUpdatesProvider
        
        Task {
            await monitorNodeUpdates()
            await monitorCacheInvalidationTriggers(
                cacheInvalidationTrigger: cacheInvalidationTrigger,
                photoLocalSource: photoLocalSource)
        }
    }
    
    deinit {
        searchAllPhotosTask?.cancel()
        monitorNodeUpdatesTask?.cancel()
        monitorCacheInvalidationTask?.cancel()
    }
    
    public func photosUpdated() async -> AnyAsyncSequence<[NodeEntity]> {
        await photosUpdateSequences.make()
    }
    
    public func allPhotos() async throws -> [NodeEntity] {
        let photosFromSource = await photoLocalSource.photos
        try Task.checkCancellation()
        if photosFromSource.isNotEmpty {
            return photosFromSource
        }
        return try await loadAllPhotos()
    }
    
    public func photo(forHandle handle: HandleEntity) async -> NodeEntity? {
        if let photoFromSource = await photoLocalSource.photo(forHandle: handle) {
            return photoFromSource
        }
        guard let photo = sdk.node(forHandle: handle)?.toNodeEntity() else {
            return nil
        }
        await photoLocalSource.setPhotos([photo])
        return photo
    }
    
    // MARK: Private
    
    private func loadAllPhotos() async throws -> [NodeEntity] {
        if let searchAllPhotosTask {
            return try await searchAllPhotosTask.value
        }
        let searchPhotosTask = Task<[NodeEntity], Error> {
            return try await searchAllPhotos()
        }
        self.searchAllPhotosTask = searchPhotosTask
        defer { self.searchAllPhotosTask = nil }
        
        return try await withTaskCancellationHandler {
            let photos = try await searchPhotosTask.value
            await photoLocalSource.setPhotos(photos)
            return photos
        } onCancel: {
            searchPhotosTask.cancel()
        }
    }
    
    private func searchAllPhotos() async throws -> [NodeEntity] {
        let photos = try await searchAllMedia(formatType: .photo)
        try Task.checkCancellation()
        let videos = try await searchAllMedia(formatType: .video)
        try Task.checkCancellation()
        return photos + videos
    }
    
    private func searchAllMedia(formatType: NodeFormatEntity) async throws -> [NodeEntity] {
        let cancelToken = MEGACancelToken()
        
        return try await withTaskCancellationHandler {
            try await withAsyncThrowingValue { completion in
                guard let rootNode = sdk.rootNode else {
                    completion(.failure(NodeErrorEntity.nodeNotFound))
                    return
                }
                let nodeListFound = sdk.nodeListSearch(for: rootNode,
                                                       search: "",
                                                       cancelToken: cancelToken,
                                                       recursive: true,
                                                       orderType: .defaultDesc,
                                                       nodeFormatType: formatType.toMEGANodeFormatType(),
                                                       folderTargetType: .all)
                
                completion(.success(nodeListFound.toNodeEntities()))
            }
        } onCancel: {
            if !cancelToken.isCancelled {
                cancelToken.cancel()
            }
        }
    }
    
    private func monitorNodeUpdates() {
        monitorNodeUpdatesTask = Task {
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
        }
    }
    
    private func updatePhotos(_ updatedPhotos: [NodeEntity]) async {
        let photosToStore = await withTaskGroup(of: NodeEntity?.self) { group in
            updatedPhotos.forEach { updatedPhoto in
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    
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

            var photos = [NodeEntity]()
            for await photo in group {
                if let photo { photos.append(photo) }
            }
            return photos
        }
        
        guard photosToStore.isNotEmpty else { return }
        await photoLocalSource.setPhotos(photosToStore)
    }
    
    private func monitorCacheInvalidationTriggers(
        cacheInvalidationTrigger: CacheInvalidationTrigger,
        photoLocalSource: some PhotoLocalSourceProtocol) {
        
        monitorCacheInvalidationTask = Task {
            guard !Task.isCancelled else {
                return
            }
            
            for await _ in await cacheInvalidationTrigger.cacheInvalidationSequence() {
                guard !Task.isCancelled else {
                    break
                }
                await photoLocalSource.removeAllPhotos()
            }
        }
    }
}
