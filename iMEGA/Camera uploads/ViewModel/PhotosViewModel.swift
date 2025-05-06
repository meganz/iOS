import Combine
import ContentLibraries
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPermissions
import MEGAPreference
import MEGASwiftUI
import SwiftUI

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
    
    let cameraUploadStatusButtonViewModel: CameraUploadStatusButtonViewModel
    
    var contentConsumptionAttributeLoadingTask: Task<Void, Never>?
    
    @Published private(set) var cameraUploadExplorerSortOrderType: SortOrderType = .newest
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private(set) var isCameraUploadsEnabled: Bool
    
    private var filterOptions: PhotosFilterOptions = [.allMedia, .allLocations]
    
    var filterType: PhotosFilterOptions = .allMedia
    var filterLocation: PhotosFilterOptions = .allLocations
    
    var isFilterActive: Bool {
        filterType != .allMedia || filterLocation != .allLocations
    }
    var isSelectHidden: Bool = false
    
    let timelineViewModel: TimeLineViewModel
        
    private var photoUpdatePublisher: PhotoUpdatePublisher
    private var photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let cameraUploadsSettingsViewRouter: any Routing
    private let tracker: any AnalyticsTracking
    private var subscriptions = Set<AnyCancellable>()
    
    init(photoUpdatePublisher: PhotoUpdatePublisher,
         photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
         devicePermissionHandler: some DevicePermissionsHandling,
         cameraUploadsSettingsViewRouter: some Routing,
         tracker: some AnalyticsTracking = DIContainer.tracker) {
        
        self.photoUpdatePublisher = photoUpdatePublisher
        self.photoLibraryUseCase = photoLibraryUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        self.timelineViewModel = TimeLineViewModel(
            cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel(
                monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                devicePermissionHandler: devicePermissionHandler)
        )
        self.cameraUploadStatusButtonViewModel = CameraUploadStatusButtonViewModel(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            preferenceUseCase: preferenceUseCase)
        self.tracker = tracker
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
            let timelineFilters = await contentConsumptionUserAttributeUseCase.fetchTimelineFilter()
            if timelineFilters.usePreference {
                filterType = filterType(from: timelineFilters.filterType)
                filterLocation = filterLocation(from: timelineFilters.filterLocation)
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
    
    func trackHideNodeMenuEvent() {
        tracker.trackAnalyticsEvent(with: TimelineHideNodeMenuItemEvent())
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
        
    // MARK: - Private
    private func loadFilteredPhotos() async throws -> [NodeEntity] {
        let filterOptions: PhotosFilterOptions = [filterType, filterLocation]
        var nodes: [NodeEntity] = try await photoLibraryUseCase.media(
            for: filterOptions.toPhotosFilterOptionsEntity(),
            excludeSensitive: nil)
        
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
        timelineViewModel.cameraUploadStatusBannerViewModel.cameraUploadStatusShown = true
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
