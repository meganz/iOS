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
            timelineViewModel.showEmptyStateView = mediaNodes.isEmpty
            photoUpdatePublisher.updatePhotoLibrary()
        }
    }
    
    let cameraUploadStatusButtonViewModel: CameraUploadStatusButtonViewModel
    
    private(set) var contentConsumptionAttributeLoadingTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var loadPhotosTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var monitorNodeUpdatesTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var currentNodeUpdateTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    
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
        
    private let photoUpdatePublisher: any PhotoUpdatePublisherProtocol
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let cameraUploadsSettingsViewRouter: any Routing
    private let tracker: any AnalyticsTracking
    private var subscriptions = Set<AnyCancellable>()
    private var pendingNodeUpdates: [NodeEntity] = []
    
    init(photoUpdatePublisher: some PhotoUpdatePublisherProtocol,
         photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
         devicePermissionHandler: some DevicePermissionsHandling,
         cameraUploadsSettingsViewRouter: some Routing,
         nodeUseCase: some NodeUseCaseProtocol,
         tracker: some AnalyticsTracking = DIContainer.tracker) {
        
        self.photoUpdatePublisher = photoUpdatePublisher
        self.photoLibraryUseCase = photoLibraryUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.nodeUseCase = nodeUseCase
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        self.timelineViewModel = TimeLineViewModel(
            cameraUploadStatusBannerViewModel: CameraUploadStatusBannerViewModel(
                monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                devicePermissionHandler: devicePermissionHandler,
                cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter),
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter
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
    
    @objc func startMonitoringUpdates() {
        monitorNodeUpdatesTask = Task { [weak self, nodeUseCase] in
            for await nodeEntities in nodeUseCase.nodeUpdates {
                self?.handleNodeUpdates(with: nodeEntities)
            }
        }
    }
    
    @objc func loadAllPhotosWithSavedFilters() {
        contentConsumptionAttributeLoadingTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let timelineFilters = await contentConsumptionUserAttributeUseCase.fetchTimelineFilter()
            if timelineFilters.usePreference {
                filterType = filterType(from: timelineFilters.filterType)
                filterLocation = filterLocation(from: timelineFilters.filterLocation)
            }
            guard !Task.isCancelled else {
                MEGALogError("[Photos] loadAllPhotosWithSavedFilters cancelled")
                return
            }
            loadAllPhotos()
        }
    }
    
    @objc func loadAllPhotos() {
        loadPhotosTask = Task(priority: .userInitiated) { [weak self] in
            await self?.loadPhotos()
        }
    }
    
    func loadPhotos() async {
        do {
            mediaNodes = try await loadFilteredPhotos()
        } catch is CancellationError {
            MEGALogError("[Photos] loadPhotos cancelled")
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
    
    func navigateToCameraUploadSettings() {
        cameraUploadsSettingsViewRouter.start()
    }
    
    @objc func cancelLoading() {
        monitorNodeUpdatesTask = nil
        contentConsumptionAttributeLoadingTask = nil
        loadPhotosTask = nil
        currentNodeUpdateTask = nil
    }
        
    // MARK: - Private
    private func loadFilteredPhotos() async throws -> [NodeEntity] {
        let filterOptions: PhotosFilterOptions = [filterType, filterLocation]
        var nodes: [NodeEntity] = try await photoLibraryUseCase.media(
            for: filterOptions.toPhotosFilterOptionsEntity(),
            excludeSensitive: nil)
        
        try Task.checkCancellation()
        
        filter(nodes: &nodes, with: filterType)
        
        return nodes
    }
    
    private func shouldProcessOnNodesUpdate(
        nodes: [NodeEntity],
        container: PhotoLibraryContainerEntity
    ) -> Bool {
        if filterLocation == .allLocations || filterLocation == .cloudDrive {
            return nodes.contains {
                $0.fileExtensionGroup.isVisualMedia && $0.hasThumbnail
            }
        } else if filterLocation == .cameraUploads {
            return shouldProcessOnNodeEntitiesUpdate(with: nodes,
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
            .sink { [weak self] _ in self?.photoUpdatePublisher.updatePhotoLibrary() }
            .store(in: &subscriptions)
    }
    
    private func shouldShowEnableCameraUploadsBanner() -> Bool {
        guard !isCameraUploadsEnabled else {
            return false
        }
        return filterLocation == .cloudDrive
    }
    
    private func handleNodeUpdates(with updatedNodes: [NodeEntity]) {
        guard currentNodeUpdateTask == nil else {
            pendingNodeUpdates.append(contentsOf: updatedNodes)
            return
        }
        processNodeUpdates(updatedNodes)
    }
    
    private func processNodeUpdates(_ nodes: [NodeEntity]) {
        currentNodeUpdateTask = Task { [weak self] in
            guard let self else { return }
            
            defer { currentNodeUpdateTask = nil }
            
            do {
                let container = await photoLibraryUseCase.photoLibraryContainer()
                
                try Task.checkCancellation()
                
                guard shouldProcessOnNodesUpdate(nodes: nodes, container: container) else { return }
                
                // Cancel any existing search before starting a new one
                loadPhotosTask = nil
                
                await loadPhotos()
                
                try Task.checkCancellation()
                
                processPendingNodeUpdates()
            } catch is CancellationError {
                MEGALogDebug("[Photos] Node update processing cancelled")
                pendingNodeUpdates.removeAll()
            } catch {
                MEGALogError("[Photos] Error processing node updates: \(error)")
                processPendingNodeUpdates()
            }
        }
    }
    
    private func processPendingNodeUpdates() {
        guard pendingNodeUpdates.isNotEmpty else { return }
        
        let nodesToProcess = pendingNodeUpdates
        pendingNodeUpdates.removeAll()
        processNodeUpdates(nodesToProcess)
    }
}

extension PhotosViewModel: NodesUpdateProtocol {}
