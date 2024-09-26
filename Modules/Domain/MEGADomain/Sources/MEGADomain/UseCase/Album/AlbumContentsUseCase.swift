import Combine

public protocol AlbumContentsUseCaseProtocol: Sendable {
    func albumReloadPublisher(forAlbum album: AlbumEntity) -> AnyPublisher<Void, Never>
    func photos(in album: AlbumEntity) async throws -> [AlbumPhotoEntity]
    func userAlbumPhotos(by id: HandleEntity, showHidden: Bool) async -> [AlbumPhotoEntity]
    func userAlbumUpdatedPublisher(for album: AlbumEntity) -> AnyPublisher<SetEntity, Never>?
    func userAlbumCoverPhoto(in album: AlbumEntity, forPhotoId photoId: HandleEntity) async -> NodeEntity?
}

public struct AlbumContentsUseCase: AlbumContentsUseCaseProtocol {
    private let albumContentsRepo: any AlbumContentsUpdateNotifierRepositoryProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let fileSearchRepo: any FilesSearchRepositoryProtocol
    private let userAlbumRepo: any UserAlbumRepositoryProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let hiddenNodesFeatureFlagEnabled: @Sendable () -> Bool
    
    public init(albumContentsRepo: any AlbumContentsUpdateNotifierRepositoryProtocol,
                mediaUseCase: any MediaUseCaseProtocol,
                fileSearchRepo: any FilesSearchRepositoryProtocol,
                userAlbumRepo: any UserAlbumRepositoryProtocol,
                contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
                photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
                sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
                hiddenNodesFeatureFlagEnabled: @escaping @Sendable () -> Bool) {
        self.albumContentsRepo = albumContentsRepo
        self.mediaUseCase = mediaUseCase
        self.fileSearchRepo = fileSearchRepo
        self.userAlbumRepo = userAlbumRepo
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.photoLibraryUseCase = photoLibraryUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.hiddenNodesFeatureFlagEnabled = hiddenNodesFeatureFlagEnabled
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
        let showHiddenPhotos = await showHiddenPhotos()
        
        if album.systemAlbum {
            return try await systemAlbumPhotos(forAlbum: album,
                                               showHiddenPhotos: showHiddenPhotos)
            .map { AlbumPhotoEntity(photo: $0) }
        }
        return await userAlbumPhotos(by: album.id,
                                     showHidden: showHiddenPhotos)
    }
    
    public func userAlbumPhotos(by id: HandleEntity,
                                showHidden: Bool) async -> [AlbumPhotoEntity] {
        await withTaskGroup(of: AlbumPhotoEntity?.self) { group in
            let albumElementIds = await userAlbumRepo.albumElementIds(
                by: id, includeElementsInRubbishBin: false)
            
            albumElementIds.forEach { albumElementId in
                group.addTask {
                    guard let photo = await photo(forNodeId: albumElementId.nodeId),
                          await shouldShowPhoto(photo, showHidden: showHidden) else {
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
    
    private func systemAlbumPhotos(forAlbum album: AlbumEntity, showHiddenPhotos: Bool) async throws -> [NodeEntity] {
        let photos = try await photoLibraryUseCase.media(for: [.allLocations, .images],
                                                         excludeSensitive: !showHiddenPhotos)
        switch album.type {
        case .favourite:
            let videos = try await photoLibraryUseCase.media(for: [.allLocations, .videos],
                                                             excludeSensitive: !showHiddenPhotos)
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
    
    private func showHiddenPhotos() async -> Bool {
        guard hiddenNodesFeatureFlagEnabled() else { return true }
        
        return await contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute()
            .showHiddenNodes
    }
    
    private func shouldShowPhoto(_ node: NodeEntity, showHidden: Bool) async -> Bool {
        guard hiddenNodesFeatureFlagEnabled(),
              !showHidden else {
            return true
        }
        return if node.isMarkedSensitive {
            false
        } else {
            (try? await !sensitiveNodeUseCase.isInheritingSensitivity(node: node)) ?? false
        }
    }
}
