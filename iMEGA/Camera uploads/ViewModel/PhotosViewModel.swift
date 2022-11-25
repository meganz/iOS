import Combine
import MEGADomain

final class PhotosViewModel: NSObject {
    @objc var mediaNodesArray: [MEGANode] = [MEGANode]() {
        didSet {
            guard cameraUploadExplorerSortOrderType != nil else { return }
            photoUpdatePublisher.updatePhotoLibrary()
        }
    }
    
    private var featureFlagProvider: FeatureFlagProviderProtocol
    private var photoUpdatePublisher: PhotoUpdatePublisher
    private var photoLibraryUseCase: PhotoLibraryUseCaseProtocol
    private var mediaUseCase: MediaUseCaseProtocol
    
    var cameraUploadExplorerSortOrderType: SortOrderType? {
        didSet {
            if let orderType = cameraUploadExplorerSortOrderType {
                mediaNodesArray = reorderPhotos(orderType, mediaNodes: mediaNodesArray)
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
        mediaUseCase: MediaUseCaseProtocol,
        featureFlagProvider: FeatureFlagProviderProtocol = FeatureFlagProvider()
    ) {
        self.photoUpdatePublisher = photoUpdatePublisher
        self.photoLibraryUseCase = photoLibraryUseCase
        self.mediaUseCase = mediaUseCase
        self.featureFlagProvider = featureFlagProvider
        super.init()
        loadSortOrderType()
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
    
    @MainActor
    @objc func loadAllPhotos() {
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.loadPhotos()
        }
    }
    
    @MainActor
    func loadFilteredPhotos() async throws -> [MEGANode] {
        let filterOptions: PhotosFilterOptions = [filterType, filterLocation]
        var nodes: [MEGANode]
        
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
    
    @MainActor
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
    
    private func loadPhotos() async {
        let photos = try? await loadFilteredPhotos()
        mediaNodesArray = photos?.filter { $0.hasThumbnail() } ?? []
    }
    
    private func shouldProcessOnNodesUpdate(
        nodeList: MEGANodeList,
        container: PhotoLibraryContainerEntity
    ) -> Bool {
        let cameraUploadNodesModified = shouldProcessOnNodesUpdate(with: nodeList,
                                                                   childNodes: mediaNodesArray,
                                                                   parentNode: container.cameraUploadNode)
        let mediaUploadNodesModified = shouldProcessOnNodesUpdate(with: nodeList,
                                                                  childNodes: mediaNodesArray,
                                                                  parentNode:  container.mediaUploadNode)
        return cameraUploadNodesModified || mediaUploadNodesModified
    }
    
    private func loadSortOrderType() {
        let sortOrderType = sortOrderType(forKey: .cameraUploadExplorerFeed)
        cameraUploadExplorerSortOrderType = sortOrderType
    }
    
    private func updateMediaNodesArray(_ photos: [MEGANode]){
        mediaNodesArray = reorderPhotos(cameraUploadExplorerSortOrderType, mediaNodes: photos)
    }
}

extension PhotosViewModel {
    func resetFilters() {
        self.filterType = .allMedia
        self.filterLocation = .allLocations
    }
}

extension PhotosViewModel: NodesUpdateProtocol {}
