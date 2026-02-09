import ContentLibraries
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAPreference
import SwiftUI

@MainActor
final class NewTimelineViewModel: ObservableObject {
    @Published private(set) var loadPhotosTaskId = UUID()
    @Published private(set) var showEmptyStateView = false
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private(set) var isCameraUploadsEnabled: Bool
    
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    let photoLibraryContentViewRouter: PhotoLibraryContentViewRouter
    
    private let cameraUploadsSettingsViewRouter: any Routing
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let tracker: any AnalyticsTracking
    
    private var isInitialLoadComplete = false
    private var pendingNodeUpdates: [NodeEntity] = []
    
    private(set) var photoFilterOptions: PhotosFilterOptionsEntity = [.allMedia, .allLocations]
    private(set) var sortOrder: SortOrderEntity = .modificationDesc
    private(set) var currentNodeUpdateTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var sortPhotoLibraryTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    
    init(
        photoLibraryContentViewModel: PhotoLibraryContentViewModel,
        photoLibraryContentViewRouter: PhotoLibraryContentViewRouter,
        cameraUploadsSettingsViewRouter: some Routing,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.photoLibraryContentViewModel = photoLibraryContentViewModel
        self.photoLibraryContentViewRouter = photoLibraryContentViewRouter
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        self.photoLibraryUseCase = photoLibraryUseCase
        self.nodeUseCase = nodeUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.tracker = tracker
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }
    
    func onViewDisappear() {
        currentNodeUpdateTask = nil
        sortPhotoLibraryTask = nil
    }
    
    func loadPhotos() async {
        defer { isInitialLoadComplete = true }
        do {
            if !isInitialLoadComplete {
                try await loadSavedFilters()
            }
            photoLibraryContentViewModel.library = try await timelinePhotoLibrary()
        } catch is CancellationError {
            MEGALogError("[\(type(of: self))] loadPhotos cancelled")
        } catch {
            MEGALogError("[\(type(of: self))] - error loading photos \(error)")
        }
    }
    
    func monitorUpdates() async {
        for await nodes in nodeUseCase.nodeUpdates where isInitialLoadComplete {
            handleNodeUpdates(with: nodes)
        }
    }
    
    func emptyScreenTypeToShow() -> PhotosEmptyScreenViewType {
        guard !isCameraUploadsEnabled else {
            return .noMediaFound
        }
        return switch photoFilterOptions {
        case [.images, .cloudDrive]:
                .noImagesFound
        case [.videos, .cloudDrive]:
                .noVideosFound
        case [.allMedia, .allLocations], [.allMedia, .cameraUploads],
            [.images, .allLocations], [.images, .cameraUploads],
            [.videos, .allLocations], [.videos, .cameraUploads]:
                .enableCameraUploads
        default: .noMediaFound
        }
    }
    
    func enableCameraUploadsBannerAction(filterLocation: PhotosFilterOptions) -> (() -> Void)? {
        guard shouldShowEnableCameraUploadsBanner(filterLocation: filterLocation) else {
            return nil
        }
        return navigateToCameraUploadSettings
    }
    
    func navigateToCameraUploadSettings() {
        cameraUploadsSettingsViewRouter.start()
    }
    
    func updateSortOrder(_ newSortOrder: SortOrderEntity) {
        guard sortOrder != newSortOrder else { return }
        sortOrder = newSortOrder
        let photos = photoLibraryContentViewModel.library.allPhotos
        
        sortPhotoLibraryTask = Task { @MainActor in
            let updatedPhotoLibrary = await buildPhotoLibrary(
                nodes: photos, sortOrder: newSortOrder)
            
            try Task.checkCancellation()
            
            photoLibraryContentViewModel.library = updatedPhotoLibrary
        }
    }
    
    func updatePhotoFilter(option: PhotosFilterOptionsEntity) async {
        let newFilterOptions = if PhotosFilterOptionsEntity.mediaOptions.contains(option) {
            option.union(photoFilterOptions.locationSelection)
        } else if PhotosFilterOptionsEntity.locationOptions.contains(option) {
            option.union(photoFilterOptions.mediaSelection)
        } else {
            option
        }
        
        guard photoFilterOptions != newFilterOptions else { return }
        tracker.trackFilterChange(new: option)
        photoFilterOptions = newFilterOptions
        loadPhotosTaskId = UUID()
        await saveFilters()
    }
    
    func updateEditMode(_ mode: EditMode) {
        photoLibraryContentViewModel.selection.editMode = mode
    }
    
    private func saveFilters() async {
        guard let mediaType = photoFilterOptions.mediaSelection.toTimelineUserAttributeMediaTypeEntity(),
              let location = photoFilterOptions.locationSelection.toTimelineUserAttributeMediaLocationEntity() else { return }
        
        do {
            let timeline = TimelineUserAttributeEntity(
                mediaType: mediaType,
                location: location,
                usePreference: true)
            
            try await contentConsumptionUserAttributeUseCase.save(timeline: timeline)
            
        } catch let error as JSONCodingErrorEntity {
            MEGALogError("[\(type(of: self))] Unable to save timeline filter. \(error.localizedDescription)")
        } catch {
            MEGALogError(error.localizedDescription)
        }
    }
    
    private func shouldShowEnableCameraUploadsBanner(filterLocation: PhotosFilterOptions) -> Bool {
        guard !isCameraUploadsEnabled else {
            return false
            
        }
        return filterLocation == .cloudDrive
    }
    
    private func timelinePhotoLibrary() async throws -> PhotoLibrary {
        let photos = try await photoLibraryUseCase.media(
            for: photoFilterOptions,
            excludeSensitive: nil)
            .lazy
            .filter(\.hasThumbnail)
        
        try Task.checkCancellation()
        
        showEmptyStateView = photos.isEmpty
        
        try Task.checkCancellation()
        
        return await buildPhotoLibrary(nodes: Array(photos), sortOrder: sortOrder)
    }
    
    private func buildPhotoLibrary(
        nodes: [NodeEntity],
        sortOrder: SortOrderEntity
    ) async -> PhotoLibrary {
        await Task.detached(priority: .userInitiated) {
            nodes.toPhotoLibrary(withSortType: sortOrder)
        }.value
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
                
                await loadPhotos()
                
                try Task.checkCancellation()
                
                processPendingNodeUpdates()
            } catch is CancellationError {
                MEGALogDebug("[\(type(of: self))] Node update processing cancelled")
                pendingNodeUpdates.removeAll()
            } catch {
                MEGALogError("[\(type(of: self))] Error processing node updates: \(error)")
                processPendingNodeUpdates()
            }
        }
    }
    
    private func shouldProcessOnNodesUpdate(
        nodes: [NodeEntity],
        container: PhotoLibraryContainerEntity
    ) -> Bool {
        let locationSelection = photoFilterOptions.locationSelection
        return if locationSelection.contains(.cloudDrive) {
            nodes.contains {
                $0.fileExtensionGroup.isVisualMedia && $0.hasThumbnail
            }
        } else if locationSelection.contains(.cameraUploads) {
            container.cameraUploadNode?.shouldProcessOnNodeEntitiesUpdate(
                withChildNodes: photoLibraryContentViewModel.library.allPhotos,
                updatedNodes: nodes) ?? false
        } else {
            false
        }
    }
    
    private func processPendingNodeUpdates() {
        guard pendingNodeUpdates.isNotEmpty else { return }
        
        let nodesToProcess = pendingNodeUpdates
        pendingNodeUpdates.removeAll()
        processNodeUpdates(nodesToProcess)
    }
    
    private func loadSavedFilters() async throws {
        let timelineAttributes = await contentConsumptionUserAttributeUseCase.fetchTimelineAttribute()
        
        try Task.checkCancellation()
        
        guard timelineAttributes.usePreference else { return }
        
        let savedFilters = timelineAttributes.toPhotoFilterOptionsEntity()
        
        guard photoFilterOptions != savedFilters else { return }
        photoFilterOptions = savedFilters
    }
}
