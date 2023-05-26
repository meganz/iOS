import Combine

public protocol AlbumContentsUseCaseProtocol {
    func albumReloadPublisher(forAlbum album: AlbumEntity) -> AnyPublisher<Void, Never>
    func photos(in album: AlbumEntity) async throws -> [AlbumPhotoEntity]
    func userAlbumPhotos(by id: HandleEntity) async -> [AlbumPhotoEntity]
    func userAlbumUpdatedPublisher(for album: AlbumEntity) -> AnyPublisher<SetEntity, Never>?
    func userAlbumCoverPhoto(in album: AlbumEntity, forPhotoId photoId: HandleEntity) async -> NodeEntity?
}

public struct AlbumContentsUseCase: AlbumContentsUseCaseProtocol {
    private let albumContentsRepo: AlbumContentsUpdateNotifierRepositoryProtocol
    private let mediaUseCase: MediaUseCaseProtocol
    private let fileSearchRepo: FilesSearchRepositoryProtocol
    private let userAlbumRepo: UserAlbumRepositoryProtocol
    
    public init(albumContentsRepo: AlbumContentsUpdateNotifierRepositoryProtocol,
                mediaUseCase: MediaUseCaseProtocol,
                fileSearchRepo: FilesSearchRepositoryProtocol,
                userAlbumRepo: UserAlbumRepositoryProtocol) {
        self.albumContentsRepo = albumContentsRepo
        self.mediaUseCase = mediaUseCase
        self.fileSearchRepo = fileSearchRepo
        self.userAlbumRepo = userAlbumRepo
    }
    
    // MARK: Protocols
    
    public func albumReloadPublisher(forAlbum album: AlbumEntity) -> AnyPublisher<Void, Never> {
        if album.type == .user {
            return userAlbumRepo.setElemetsUpdatedPublisher
                .filter { $0.contains(where: { $0.ownerId == album.id }) }
                .map { _ in ()}
                .eraseToAnyPublisher()
                .merge(with: albumContentsRepo.albumReloadPublisher)
                .eraseToAnyPublisher()
        }
        return albumContentsRepo.albumReloadPublisher
    }
    
    public func photos(in album: AlbumEntity) async throws -> [AlbumPhotoEntity] {
        if album.systemAlbum {
            return try await filter(forAlbum: album).compactMap {
                guard $0.mediaType != nil else {
                    return nil
                }
                return AlbumPhotoEntity(photo: $0)
            }
        } else {
            return await userAlbumPhotos(by: album.id)
        }
    }
    
    public func userAlbumPhotos(by id: HandleEntity) async -> [AlbumPhotoEntity] {
        await withTaskGroup(of: AlbumPhotoEntity?.self) { group in
            let albumContent = await userAlbumRepo.albumContent(by: id, includeElementsInRubbishBin: false)
            albumContent.forEach { setElement in
                group.addTask {
                    guard let photo = await photo(forNodeId: setElement.nodeId) else {
                        return nil
                    }
                    return AlbumPhotoEntity(photo: photo,
                                            albumPhotoId: setElement.id)
                }
            }
            
            return await group.reduce(into: [AlbumPhotoEntity](), {
                if let photo = $1 { $0.append(photo) }
            })
        }
    }
    
    public func userAlbumUpdatedPublisher(for album: AlbumEntity) -> AnyPublisher<SetEntity, Never>? {
        guard album.type == .user else {
            return nil
        }
        return userAlbumRepo.setsUpdatedPublisher
            .compactMap { $0.first(where: { $0.id == album.id }) }
            .eraseToAnyPublisher()
    }
    
    public func userAlbumCoverPhoto(in album: AlbumEntity, forPhotoId photoId: HandleEntity) async -> NodeEntity? {
        guard album.type == .user,
              let setElement = await userAlbumRepo.albumElement(by: album.id,
                                                                elementId: photoId) else {
            return nil
        }
        return await photo(forNodeId: setElement.nodeId)
    }
    
    // MARK: Private
    
    private func filter(forAlbum album: AlbumEntity) async throws -> [NodeEntity] {
        async let photos = try await mediaUseCase.allPhotos()
        var nodes = [NodeEntity]()
        
        if album.type == .favourite {
            async let videos = try mediaUseCase.allVideos()
            nodes = try await [photos, videos]
                .flatMap { $0 }
                .filter { $0.hasThumbnail && $0.isFavourite }
        } else if album.type == .raw {
            nodes = try await photos.filter { $0.hasThumbnail && mediaUseCase.isRawImage($0.name) }
        } else if album.type == .gif {
            nodes = try await photos.filter { $0.hasThumbnail && mediaUseCase.isGifImage($0.name) }
        }
        
        return nodes
    }
    
    private func photo(forNodeId nodeId: HandleEntity) async -> NodeEntity? {
        guard let photo = await fileSearchRepo.node(by: nodeId),
              photo.mediaType != nil else {
            return nil
        }
        return photo
    }
}
