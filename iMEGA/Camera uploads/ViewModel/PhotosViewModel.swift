import Combine
import MEGADomain

@MainActor
final class PhotosViewModel: NSObject {
    var mediaNodes: [NodeEntity] = [NodeEntity]() {
        didSet {
            photoUpdatePublisher.updatePhotoLibrary()
        }
    }
    
    private var featureFlagProvider: FeatureFlagProviderProtocol
    private var photoUpdatePublisher: PhotoUpdatePublisher
    private var photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    
    var cameraUploadExplorerSortOrderType: SortOrderType = .newest {
        didSet {
            if cameraUploadExplorerSortOrderType != oldValue {
                photoUpdatePublisher.updatePhotoLibrary()
            }
        }
    }
    
    enum SortingKeys: String {
        case cameraUploadExplorerFeed
    }
    
    private var filterOptions: PhotosFilterOptions = [.allMedia, .allLocations]
    
    var filterType: PhotosFilterOptions = .allMedia
    var filterLocation: PhotosFilterOptions = .allLocations
    
    var isFilterActive: Bool {
        filterType != .allMedia || filterLocation != .allLocations
    }
    
    init(
        photoUpdatePublisher: PhotoUpdatePublisher,
        photoLibraryUseCase: PhotoLibraryUseCaseProtocol,
        featureFlagProvider: FeatureFlagProviderProtocol = FeatureFlagProvider()
    ) {
        self.photoUpdatePublisher = photoUpdatePublisher
        self.photoLibraryUseCase = photoLibraryUseCase
        self.featureFlagProvider = featureFlagProvider
        super.init()
        cameraUploadExplorerSortOrderType = sortOrderType(forKey: .cameraUploadExplorerFeed)
    }
    
    @objc func onCameraAndMediaNodesUpdate(nodeList: MEGANodeList) {
        Task { [weak self] in
            do {
                guard let container = await self?.photoLibraryUseCase.photoLibraryContainer() else { return }
                guard self?.shouldProcessOnNodesUpdate(nodeList: nodeList, container: container) == true else { return }
                await self?.loadPhotos()
            }
        }
    }
    
    @objc func loadAllPhotos() {
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.loadPhotos()
        }
    }
    
    func loadPhotos() async {
        do {
            mediaNodes = try await loadFilteredPhotos()
        } catch {
            MEGALogError("[Photos] - error when to load photos \(error)")
        }
    }
    
    func updateFilter(
        filterType: PhotosFilterOptions,
        filterLocation: PhotosFilterOptions
    ) {
        guard self.filterType != filterType || self.filterLocation != filterLocation else { return }
        
        self.filterType = filterType
        self.filterLocation = filterLocation
        loadAllPhotos()
    }
    
    // MARK: - Private
    private func loadFilteredPhotos() async throws -> [NodeEntity] {
        let filterOptions: PhotosFilterOptions = [filterType, filterLocation]
        var nodes: [NodeEntity]
        
        switch filterOptions {
        case .allVisualFiles, .allImages, .allVideos:
            nodes = try await photoLibraryUseCase.allPhotos()
        case .cloudDriveAll, .cloudDriveImages, .cloudDriveVideos:
            nodes = try await photoLibraryUseCase.allPhotosFromCloudDriveOnly()
        case .cameraUploadAll, .cameraUploadImages, .cameraUploadVideos:
            nodes = try await photoLibraryUseCase.allPhotosFromCameraUpload()
        default: nodes = []
        }
        
        filter(nodes: &nodes, with: filterType)
        
        return nodes
    }
    
    private func shouldProcessOnNodesUpdate(
        nodeList: MEGANodeList,
        container: PhotoLibraryContainerEntity
    ) -> Bool {
        if filterLocation == .allLocations || filterLocation == .cloudDrive {
            return nodeList.toNodeEntities()
                .contains(where: {
                    ($0.name.mnz_isImagePathExtension || $0.name.mnz_isVideoPathExtension) && $0.hasThumbnail
                })
        } else if filterLocation == .cameraUploads {
            return shouldProcessOnNodeEntitiesUpdate(with: nodeList,
                                                     childNodes: mediaNodes,
                                                     parentNode: container.cameraUploadNode)
        }
        
        return false
    }
    
    private func loadSortOrderType() {

    }
}

extension PhotosViewModel {
    func resetFilters() {
        self.filterType = .allMedia
        self.filterLocation = .allLocations
    }
}

extension PhotosViewModel: NodesUpdateProtocol {}
