import Combine

public protocol AlbumContentsUseCaseProtocol: Sendable {
    func albumReloadPublisher(forAlbum album: AlbumEntity) -> AnyPublisher<Void, Never>
    func photos(in album: AlbumEntity) async throws -> [AlbumPhotoEntity]
    func userAlbumPhotos(by id: HandleEntity, excludeSensitive: Bool) async -> [AlbumPhotoEntity]
    func userAlbumUpdatedPublisher(for album: AlbumEntity) -> AnyPublisher<SetEntity, Never>?
    func userAlbumCoverPhoto(in album: AlbumEntity, forPhotoId photoId: HandleEntity) async -> NodeEntity?
}

public struct AlbumContentsUseCase: AlbumContentsUseCaseProtocol {
    private let albumContentsRepo: any AlbumContentsUpdateNotifierRepositoryProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let fileSearchRepo: any FilesSearchRepositoryProtocol
    private let userAlbumRepo: any UserAlbumRepositoryProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    
    public init(albumContentsRepo: any AlbumContentsUpdateNotifierRepositoryProtocol,
                mediaUseCase: any MediaUseCaseProtocol,
                fileSearchRepo: any FilesSearchRepositoryProtocol,
                userAlbumRepo: any UserAlbumRepositoryProtocol,
                sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
                photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
                sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol) {
        self.albumContentsRepo = albumContentsRepo
        self.mediaUseCase = mediaUseCase
        self.fileSearchRepo = fileSearchRepo
        self.userAlbumRepo = userAlbumRepo
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.photoLibraryUseCase = photoLibraryUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
    }
    
    // MARK: Protocols
    
    public func albumReloadPublisher(forAlbum album: AlbumEntity) -> AnyPublisher<Void, Never> {
        if album.type == .user {
            return userAlbumRepo.setElementsUpdatedPublisher
                .filter { $0.contains(where: { $0.ownerId == album.id }) }
                .map { _ in ()}
                .eraseToAnyPublisher()
                .merge(with: albumContentsRepo.albumReloadPublisher)
                .eraseToAnyPublisher()
        }
        return albumContentsRepo.albumReloadPublisher
    }
    
    public func photos(in album: AlbumEntity) async throws -> [AlbumPhotoEntity] {
        let excludeSensitive = await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        
        if album.systemAlbum {
            return try await systemAlbumPhotos(forAlbum: album,
                                               excludeSensitive: excludeSensitive)
            .map { AlbumPhotoEntity(photo: $0) }
        }
        return await userAlbumPhotos(by: album.id,
                                     excludeSensitive: excludeSensitive)
    }
    
    public func userAlbumPhotos(by id: HandleEntity,
                                excludeSensitive: Bool) async -> [AlbumPhotoEntity] {
        await withTaskGroup(of: AlbumPhotoEntity?.self) { group in
            let albumElementIds = await userAlbumRepo.albumElementIds(
                by: id, includeElementsInRubbishBin: false)
            
            albumElementIds.forEach { albumElementId in
                group.addTask {
                    guard let photo = await photo(forNodeId: albumElementId.nodeId),
                          await shouldShowPhoto(photo, excludeSensitive: excludeSensitive) else {
                        return nil
                    }
                    return AlbumPhotoEntity(photo: photo,
                                            albumPhotoId: albumElementId.id)
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
            .compactMap { $0.first(where: { $0.id == album.setIdentifier }) }
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
    
    private func systemAlbumPhotos(forAlbum album: AlbumEntity, excludeSensitive: Bool) async throws -> [NodeEntity] {
        let photos = try await photoLibraryUseCase.media(for: [.allLocations, .images],
                                                         excludeSensitive: excludeSensitive)
        switch album.type {
        case .favourite:
            let videos = try await photoLibraryUseCase.media(for: [.allLocations, .videos],
                                                             excludeSensitive: excludeSensitive)
            return (photos + videos)
                .filter { $0.hasThumbnail && $0.name.fileExtensionGroup.isVisualMedia && $0.isFavourite }
        case .raw:
            return photos.filter { $0.hasThumbnail && mediaUseCase.isRawImage($0.name) }
        case .gif:
            return photos.filter { $0.hasThumbnail && mediaUseCase.isGifImage($0.name) }
        default:
            return []
        }
    }
    
    private func photo(forNodeId nodeId: HandleEntity) async -> NodeEntity? {
        guard let photo = await fileSearchRepo.node(by: nodeId),
              photo.name.fileExtensionGroup.isVisualMedia else {
            return nil
        }
        return photo
    }
    
    private func shouldShowPhoto(_ node: NodeEntity, excludeSensitive: Bool) async -> Bool {
        guard excludeSensitive else {
            return true
        }
        return if node.isMarkedSensitive {
            false
        } else {
            (try? await !sensitiveNodeUseCase.isInheritingSensitivity(node: node)) ?? false
        }
    }
}
