import MEGADomain
import MEGASdk
import MEGASwift

public actor PhotosRepository: PhotosRepositoryProtocol {
    public static let sharedRepo = PhotosRepository(sdk: .sharedSdk,
                                                    photoLocalSource: PhotosInMemoryCache.shared)
    
    private let sdk: MEGASdk
    private let photoLocalSource: any PhotoLocalSourceProtocol
    
    private var searchAllPhotosTask: Task<[NodeEntity], Error>?
    
    public init(sdk: MEGASdk,
                photoLocalSource: some PhotoLocalSourceProtocol) {
        self.sdk = sdk
        self.photoLocalSource = photoLocalSource
    }
    
    deinit {
        searchAllPhotosTask?.cancel()
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
}
