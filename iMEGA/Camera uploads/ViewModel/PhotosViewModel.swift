import Combine
import MEGADomain
import MEGAPresentation

@MainActor
final class PhotosViewModel: NSObject {
    var mediaNodes: [NodeEntity] = [NodeEntity]() {
        didSet {
            photoUpdatePublisher.updatePhotoLibrary()
        }
    }
    
    private var featureFlagProvider: FeatureFlagProviderProtocol
    private var photoUpdatePublisher: PhotoUpdatePublisher
    private var photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let userAttributeUseCase: any UserAttributeUseCaseProtocol
    
    var contentConsumptionAttributeLoadingTask: Task<Void, Never>?
    
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
    var isSelectHidden: Bool = false
    
    init(
        photoUpdatePublisher: PhotoUpdatePublisher,
        photoLibraryUseCase: any PhotoLibraryUseCaseProtocol,
        userAttributeUseCase: any UserAttributeUseCaseProtocol,
        featureFlagProvider: FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.photoUpdatePublisher = photoUpdatePublisher
        self.photoLibraryUseCase = photoLibraryUseCase
        self.userAttributeUseCase = userAttributeUseCase
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
    
    @objc func loadAllPhotosWithSavedFilters() {
        contentConsumptionAttributeLoadingTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                if featureFlagProvider.isFeatureFlagEnabled(for: .timelinePreferenceSaving),
                   let timelineFilters = try await userAttributeUseCase.timelineFilter(), timelineFilters.usePreference {
                    filterType = filterType(from: timelineFilters.filterType)
                    filterLocation = filterLocation(from: timelineFilters.filterLocation)
                }
            } catch {
                MEGALogError("[Timeline Filter] when to load saved filters \(error.localizedDescription)")
            }

            loadAllPhotos()
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
    
    func filterType(from type: PhotosFilterType) -> PhotosFilterOptions {
        switch type {
        case .images: return .images
        case .videos: return .videos
        default: return .allMedia
        }
    }
    
    func filterLocation(from location: PhotosFilterLocation) -> PhotosFilterOptions {
        switch location {
        case .cloudDrive: return .cloudDrive
        case .cameraUploads: return .cameraUploads
        default: return .allLocations
        }
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
}

extension PhotosViewModel {
    func resetFilters() {
        self.filterType = .allMedia
        self.filterLocation = .allLocations
    }
}

extension PhotosViewModel: NodesUpdateProtocol {}
