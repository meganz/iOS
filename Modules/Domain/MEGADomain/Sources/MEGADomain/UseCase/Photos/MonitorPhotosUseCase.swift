import AsyncAlgorithms
import MEGASwift

public protocol MonitorPhotosUseCaseProtocol: Sendable {
    /// Infinite `AnyAsyncSequence` returning photos for `PhotosFilterOptionsEntity` or `Error` in Result type
    ///
    /// The async sequence will immediately return photos and photos with updates when required.
    /// The async sequence is infinite and will require cancellation
    ///
    /// - Parameters:
    ///  - filterOptions: filter options to apply on photos
    ///  - excludeSensitive: Determines if sensitive nodes should be excluded
    /// - Throws: `CancellationError`
    func monitorPhotos(
        filterOptions: PhotosFilterOptionsEntity,
        excludeSensitive: Bool
    ) async -> AnyAsyncSequence<Result<[NodeEntity], Error>>
}

private typealias NodeEntityFilter = (@Sendable (NodeEntity) -> Bool)

public struct MonitorPhotosUseCase: MonitorPhotosUseCaseProtocol {
    private let photosRepository: any PhotosRepositoryProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    
    public init(photosRepository: some PhotosRepositoryProtocol,
                photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
                sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol) {
        self.photosRepository = photosRepository
        self.photoLibraryUseCase = photoLibraryUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
    }
    
    public func monitorPhotos(
        filterOptions: PhotosFilterOptionsEntity,
        excludeSensitive: Bool)
    async -> AnyAsyncSequence<Result<[NodeEntity], Error>> {
        let filters = await makeNodeFilters(filterOptions)
        guard filters.isNotEmpty else {
            return await monitorPhotos(excludeSensitive: excludeSensitive)
        }
        return await monitorPhotos(nodeEntityFilter: { node in filters.allSatisfy({ $0(node)}) },
                                   excludeSensitive: excludeSensitive)
    }
    
    // MARK: - Private
    
    private func monitorPhotos(
        nodeEntityFilter predicate: NodeEntityFilter? = nil,
        excludeSensitive: Bool
    ) async -> AnyAsyncSequence<Result<[NodeEntity], Error>> {
        let monitorAll = await updatePhotos()
            .map {
                await allPhotos(excludeSensitive: excludeSensitive)
            }
            .prepend {
                await allPhotos(excludeSensitive: excludeSensitive)
            }
        
        guard let predicate else {
            return monitorAll.eraseToAnyAsyncSequence()
        }
        
        return monitorAll
            .map {
                $0.map { $0.filter(predicate) }
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func makeNodeFilters(_ filterOptions: PhotosFilterOptionsEntity) async -> [NodeEntityFilter] {
        var filters = [NodeEntityFilter]()
        if let locationFilter = await makeLocationNodeFilters(filterOptions: filterOptions) {
            filters.append(locationFilter)
        }
        if let mediaNodeFilter = makeMediaNodeFilter(filterOptions: filterOptions) {
            filters.append(mediaNodeFilter)
        }
        if filterOptions.contains(.favourites) {
            filters.append { $0.isFavourite }
        }
        return filters
    }
    
    private func makeLocationNodeFilters(filterOptions: PhotosFilterOptionsEntity) async -> NodeEntityFilter? {
        guard !filterOptions.isSuperset(of: .allLocations) else {
            return nil
        }
        
        let container = await photoLibraryUseCase.photoLibraryContainer()
        let cameraUploadHandles = [container.cameraUploadNode?.handle,
                                   container.mediaUploadNode?.handle]
        if filterOptions.contains(.cloudDrive) {
            return { cameraUploadHandles.notContains($0.parentHandle) }
        } else if filterOptions.contains(.cameraUploads) {
            return { cameraUploadHandles.contains($0.parentHandle) }
        }
        return nil
    }
    
    private func makeMediaNodeFilter(filterOptions: PhotosFilterOptionsEntity) -> NodeEntityFilter? {
        if filterOptions.isSuperset(of: .allMedia) {
            return { $0.hasThumbnail }
        } else if filterOptions.contains(.images) {
            return { $0.name.fileExtensionGroup.isImage && $0.hasThumbnail }
        } else if filterOptions.contains(.videos) {
            return { $0.name.fileExtensionGroup.isVideo && $0.hasThumbnail }
        }
        return nil
    }
    
    private func allPhotos(excludeSensitive: Bool) async -> Result<[NodeEntity], Error> {
        do {
            let photos = try await photosRepository.allPhotos(excludeSensitive: excludeSensitive)
            return .success(photos)
        } catch {
            return .failure(error)
        }
    }

    private func updatePhotos() async -> AnyAsyncSequence<Void> {
        let photosUpdated = await photosRepository
            .photosUpdated()
            .map { _ in () }
        
        return merge(photosUpdated,
                     sensitiveNodeUseCase.folderSensitivityChanged())
        .eraseToAnyAsyncSequence()
    }
}
