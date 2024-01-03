import Combine
import MEGADomain
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo

enum PhotosEmptyScreenViewType {
    case noMediaFound
    case noImagesFound
    case noVideosFound
    case enableCameraUploads
}

@MainActor
final class PhotosViewModel: NSObject {
    var mediaNodes: [NodeEntity] = [NodeEntity]() {
        didSet {
            photoUpdatePublisher.updatePhotoLibrary()
        }
    }
    
    var cameraUploadStatusButtonViewModel = CameraUploadStatusButtonViewModel(monitorCameraUploadUseCase: FakeCameraUploadSuccessfulUseCase()) {
        didSet {
            cameraUploadStatusButtonViewModel.onTappedHandler = cameraUploadStatusButtonTapped
        }
    }
    
    @objc let timelineCameraUploadStatusFeatureEnabled: Bool
    var contentConsumptionAttributeLoadingTask: Task<Void, Never>?
    
    @Published private(set) var cameraUploadExplorerSortOrderType: SortOrderType = .newest
    
    @PreferenceWrapper(key: .isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool
    
    private var filterOptions: PhotosFilterOptions = [.allMedia, .allLocations]
    
    var filterType: PhotosFilterOptions = .allMedia
    var filterLocation: PhotosFilterOptions = .allLocations
    
    var isFilterActive: Bool {
        filterType != .allMedia || filterLocation != .allLocations
    }
    var isSelectHidden: Bool = false
    
    let timelineViewModel: CameraUploadStatusBannerViewModel
    
    private var photoUpdatePublisher: PhotoUpdatePublisher
    private var photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let userAttributeUseCase: any UserAttributeUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let cameraUploadsSettingsViewRouter: any Routing
    private var subscriptions = Set<AnyCancellable>()
    
    init(photoUpdatePublisher: PhotoUpdatePublisher,
         photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
         userAttributeUseCase: some UserAttributeUseCaseProtocol,
         sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
         devicePermissionHandler: some DevicePermissionsHandling,
         cameraUploadsSettingsViewRouter: some Routing,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.photoUpdatePublisher = photoUpdatePublisher
        self.photoLibraryUseCase = photoLibraryUseCase
        self.userAttributeUseCase = userAttributeUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        self.timelineCameraUploadStatusFeatureEnabled = featureFlagProvider.isFeatureFlagEnabled(for: .timelineCameraUploadStatus)
        self.timelineViewModel = CameraUploadStatusBannerViewModel(
            monitorCameraUploadUseCase: FakeCameraUploadSuccessfulUseCase(),
            networkMonitorUseCase: networkMonitorUseCase,
            preferenceUseCase: preferenceUseCase,
            devicePermissionHandler: devicePermissionHandler,
            featureFlagProvider: featureFlagProvider)
        
        super.init()
        $isCameraUploadsEnabled.useCase = preferenceUseCase
        
        monitorSortOrderSubscription()
        cameraUploadStatusButtonViewModel.onTappedHandler = cameraUploadStatusButtonTapped
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
            guard let self else { return }
            
            do {
                if let timelineFilters = try await userAttributeUseCase.timelineFilter(), timelineFilters.usePreference {
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
    
    // MARK: - Sort
    func update(sortOrderType: SortOrderType) {
        sortOrderPreferenceUseCase.save(
            sortOrder: sortOrderType.toSortOrderEntity(),
            for: .cameraUploadExplorerFeed)
    }
    
    // MARK: - Empty Screen
    func emptyScreenTypeToShow() -> PhotosEmptyScreenViewType {
        guard !isCameraUploadsEnabled else {
            return .noMediaFound
        }
        switch [filterType, filterLocation] {
        case [.images, .cloudDrive]:
            return .noImagesFound
        case [.videos, .cloudDrive]:
            return .noVideosFound
        case [.allMedia, .allLocations], [.allMedia, .cameraUploads],
            [.images, .allLocations], [.images, .cameraUploads],
            [.videos, .allLocations], [.videos, .cameraUploads]:
            return .enableCameraUploads
        default:
            return .noMediaFound
        }
    }
    
    func enableCameraUploadsBannerAction() -> (() -> Void)? {
        guard shouldShowEnableCameraUploadsBanner() else {
            return nil
        }
        return navigateToCameraUploadSettings
    }
    
    func navigateToCameraUploadSettings() {
        cameraUploadsSettingsViewRouter.start()
    }
    
    func change(monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol) {
        cameraUploadStatusButtonViewModel = CameraUploadStatusButtonViewModel(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase)
        timelineViewModel.change(monitorCameraUploadUseCase: monitorCameraUploadUseCase)
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
            return nodeList.toNodeEntities().contains {
                $0.fileExtensionGroup.isVisualMedia && $0.hasThumbnail
            }
        } else if filterLocation == .cameraUploads {
            return shouldProcessOnNodeEntitiesUpdate(with: nodeList,
                                                     childNodes: mediaNodes,
                                                     parentNode: container.cameraUploadNode)
        }
        
        return false
    }
        
    private func cameraUploadStatusButtonTapped() {
        guard isCameraUploadsEnabled else {
            return navigateToCameraUploadSettings()
        }
        showCameraUploadStatusBanner()
    }
    
    private func showCameraUploadStatusBanner() {
        timelineViewModel.cameraUploadStatusShown = true
    }
    
    private func monitorSortOrderSubscription() {
        sortOrderPreferenceUseCase
            .monitorSortOrder(for: .cameraUploadExplorerFeed)
            .map { sortOrderType -> SortOrderType in
                switch sortOrderType.toSortOrderType() {
                case .oldest:
                    return .oldest
                default:
                    return .newest
                }
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.cameraUploadExplorerSortOrderType = $0 }
            .store(in: &subscriptions)
        
        $cameraUploadExplorerSortOrderType
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak photoUpdatePublisher] _ in photoUpdatePublisher?.updatePhotoLibrary() }
            .store(in: &subscriptions)
    }
    
    private func shouldShowEnableCameraUploadsBanner() -> Bool {
        guard !isCameraUploadsEnabled else {
            return false
        }
        return filterLocation == .cloudDrive
    }
}

extension PhotosViewModel: NodesUpdateProtocol {}
