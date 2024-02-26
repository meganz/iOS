import MEGASwift

public protocol MonitorPhotosUseCaseProtocol: Sendable {
    /// Infinite `AnyAsyncSequence` returning photos for `PhotosFilterOptionsEntity`
    ///
    /// The async sequence will immediately return photos and photos with updates when required.
    /// The async sequence is infinite and will require cancellation
    ///
    /// - Parameter filterOptions: filter options to apply on photos
    /// - Throws: `CancellationError`
    func monitorPhotos(filterOptions: PhotosFilterOptionsEntity) async throws -> AnyAsyncSequence<[NodeEntity]>
}

private typealias NodeEntityFilter = ((NodeEntity) -> Bool)

public struct MonitorPhotosUseCase: MonitorPhotosUseCaseProtocol {
    private let photosRepository: any PhotosRepositoryProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    
    public init(photosRepository: some PhotosRepositoryProtocol,
                photoLibraryUseCase: some PhotoLibraryUseCaseProtocol) {
        self.photosRepository = photosRepository
        self.photoLibraryUseCase = photoLibraryUseCase
    }
    
    public func monitorPhotos(filterOptions: PhotosFilterOptionsEntity) async throws -> AnyAsyncSequence<[NodeEntity]> {
        let filters = await makeNodeFilters(filterOptions)
        guard filters.isNotEmpty else {
            return try await monitorPhotos()
        }
        return try await monitorPhotos(nodeEntityFilter: { node in filters.allSatisfy({ $0(node)}) })
    }
    
    // MARK: - Private
    
    private func monitorPhotos(nodeEntityFilter predicate: NodeEntityFilter? = nil) async throws -> AnyAsyncSequence<[NodeEntity]> {
        let allPhotos = try await photosRepository.allPhotos()
        
        let monitorAll = await photosRepository
            .photosUpdated()
            .prepend(allPhotos)
        
        guard let predicate else {
            return monitorAll.eraseToAnyAsyncSequence()
        }
        
        return monitorAll
            .map {
                $0.filter(predicate)
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
}
