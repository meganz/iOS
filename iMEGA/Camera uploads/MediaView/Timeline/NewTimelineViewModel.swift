import ContentLibraries
import MEGAAppPresentation
import MEGADomain
import MEGAPreference

@MainActor
final class NewTimelineViewModel: ObservableObject {
    @Published private(set) var showEmptyStateView = false
    @Published private(set) var sortOrder: SortOrderEntity = .modificationDesc
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private(set) var isCameraUploadsEnabled: Bool
    
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    let photoLibraryContentViewRouter: PhotoLibraryContentViewRouter
    
    private let cameraUploadsSettingsViewRouter: any Routing
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    
    private var isInitialLoadComplete = false
    private var filterType: PhotosFilterOptionsEntity = .allMedia
    private var filterLocation: PhotosFilterOptionsEntity = .allLocations
    private var pendingNodeUpdates: [NodeEntity] = []
    
    private(set) var currentNodeUpdateTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    
    init(
        photoLibraryContentViewModel: PhotoLibraryContentViewModel,
        photoLibraryContentViewRouter: PhotoLibraryContentViewRouter,
        cameraUploadsSettingsViewRouter: some Routing,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol
    ) {
        self.photoLibraryContentViewModel = photoLibraryContentViewModel
        self.photoLibraryContentViewRouter = photoLibraryContentViewRouter
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        self.photoLibraryUseCase = photoLibraryUseCase
        self.nodeUseCase = nodeUseCase
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }
    
    func loadPhotos() async {
        defer { isInitialLoadComplete = true }
        do {
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
    
    func emptyScreenTypeToShow(
        filterType: PhotosFilterOptions,
        filterLocation: PhotosFilterOptions
    ) -> PhotosEmptyScreenViewType {
        guard !isCameraUploadsEnabled else {
            return .noMediaFound
        }
        return switch [filterType, filterLocation] {
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
    
    private func shouldShowEnableCameraUploadsBanner(filterLocation: PhotosFilterOptions) -> Bool {
        guard !isCameraUploadsEnabled else {
            return false
            
        }
        return filterLocation == .cloudDrive
    }
    
    private func timelinePhotoLibrary() async throws -> PhotoLibrary {
        let filterOptions: PhotosFilterOptionsEntity = [filterType, filterLocation]
        let photos = try await photoLibraryUseCase.media(
            for: filterOptions,
            excludeSensitive: nil)
            .lazy
            .filter(\.hasThumbnail)
        
        showEmptyStateView = photos.isEmpty
        
        try Task.checkCancellation()
        
        return Array(photos).toPhotoLibrary(withSortType: sortOrder)
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
        return if filterLocation == .allLocations || filterLocation == .cloudDrive {
            nodes.contains {
                $0.fileExtensionGroup.isVisualMedia && $0.hasThumbnail
            }
        } else if filterLocation == .cameraUploads {
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
}
