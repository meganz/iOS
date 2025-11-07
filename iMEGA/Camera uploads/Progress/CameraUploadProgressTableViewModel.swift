import MEGADomain
import MEGARepo

@MainActor
final class CameraUploadProgressTableViewModel: ObservableObject {
    enum InProgressSnapshotUpdate: Equatable {
        case initialLoad([CameraUploadInProgressRowViewModel])
        case itemAdded(CameraUploadInProgressRowViewModel)
        case itemRemoved(CameraUploadLocalIdentifierEntity)
    }
    enum InQueueSnapshotUpdate: Equatable {
        case initial([CameraUploadInQueueRowViewModel])
        case updated([CameraUploadInQueueRowViewModel])
        case itemRemoved(CameraUploadLocalIdentifierEntity)
    }
    // MARK: - Published Properties
    @Published private(set) var inProgressSnapshotUpdate: InProgressSnapshotUpdate?
    @Published private(set) var inQueueSnapshotUpdate: InQueueSnapshotUpdate?
    
    // MARK: - Private Properties
    private let cameraUploadProgressUseCase: any CameraUploadProgressUseCaseProtocol
    private let cameraUploadFileDetailsUseCase: any CameraUploadFileDetailsUseCaseProtocol
    private let photoLibraryThumbnailUseCase: any PhotoLibraryThumbnailUseCaseProtocol
    private let thumbnailSize: CGSize = .init(width: 32, height: 32)
    private let paginationManager: any CameraUploadPaginationManagerProtocol
    private let pageSize: Int
    
    private var firstPageIndex: Int = 0
    private var lastPageIndex: Int = 0
    private var isInitialLoad = true
    private var lastProcessedPageIndex: Int?
    private(set) var isPaginationInProgress = false
    private var hasHandledProgrammaticScrollNearEdge = false
    
    // MARK: - Internal Properties
    let rowHeight: CGFloat = 60
    
    init(
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol,
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol,
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol,
        paginationManager: some CameraUploadPaginationManagerProtocol
    ) {
        self.cameraUploadProgressUseCase = cameraUploadProgressUseCase
        self.cameraUploadFileDetailsUseCase = cameraUploadFileDetailsUseCase
        self.photoLibraryThumbnailUseCase = photoLibraryThumbnailUseCase
        self.paginationManager = paginationManager
        self.pageSize = paginationManager.pageSize
    }
    
    deinit {
        photoLibraryThumbnailUseCase.clearCache()
        Task { [weak paginationManager] in
            await paginationManager?.cancelAll()
        }
    }
    
    func loadInitial() async {
        do {
            async let inProgressFiles = cameraUploadProgressUseCase.inProgressFiles()
            async let update =  paginationManager.loadInitialPage()
            let (inProgress, inQueueUpdate) = try await (inProgressFiles, update)
            
            try Task.checkCancellation()
            let allLocalIdentifiers = inProgress.map(\.localIdentifier) + inQueueUpdate.items.map(\.localIdentifier)
            if allLocalIdentifiers.isNotEmpty {
                photoLibraryThumbnailUseCase.startCaching(
                    for: allLocalIdentifiers, targetSize: thumbnailSize)
            }
            
            let inProgressVMs = inProgress.map {
                CameraUploadInProgressRowViewModel(
                    fileEntity: $0,
                    cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                    photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
                    thumbnailSize: thumbnailSize)
            }
            
            try Task.checkCancellation()
            
            inProgressSnapshotUpdate = .initialLoad(inProgressVMs)
            applyInQueueUpdate(inQueueUpdate)
            isInitialLoad = false
        } catch {
            MEGALogError("[\(type(of: self))] initial load failed error: \(error)")
        }
    }
    
    func monitorActiveUploads() async {
        for await phaseEvent in await cameraUploadProgressUseCase.cameraUploadPhaseEventUpdates {
            guard !Task.isCancelled else { break }
            
            switch phaseEvent.phase {
            case .uploading:
                guard let fileEntity = try? await cameraUploadFileDetailsUseCase.fileDetails(
                    for: phaseEvent.assetIdentifier) else {
                    continue
                }
                
                inProgressSnapshotUpdate = .itemAdded(.init(
                    fileEntity: fileEntity,
                    cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                    photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
                    thumbnailSize: thumbnailSize))
                
                await paginationManager.removeItemFromPages(localIdentifier: phaseEvent.assetIdentifier)
                inQueueSnapshotUpdate = .itemRemoved(phaseEvent.assetIdentifier)
                
            case .completed:
                inProgressSnapshotUpdate = .itemRemoved(phaseEvent.assetIdentifier)
                
                photoLibraryThumbnailUseCase.stopCaching(
                    for: [phaseEvent.assetIdentifier], targetSize: thumbnailSize)
            default: continue
            }
        }
    }
    
    func handleQueueSectionScroll(
        visibleIndex: Int,
        totalVisibleItems: Int,
        isUserInitiated: Bool
    ) async {
        guard !isPaginationInProgress else {
            MEGALogDebug("[\(type(of: self))] Pagination already in progress, skipping")
            return
        }
        
        let edgeThreshold = pageSize
        let isNearEdge = visibleIndex < edgeThreshold || visibleIndex >= (totalVisibleItems - edgeThreshold)
        
        if !isNearEdge && isUserInitiated {
            hasHandledProgrammaticScrollNearEdge = false
        }
        
        if !isUserInitiated {
            let isNearBottomEdge = visibleIndex >= (totalVisibleItems - edgeThreshold)
            guard isNearBottomEdge && !hasHandledProgrammaticScrollNearEdge else {
                MEGALogDebug("[\(type(of: self))] Ignoring programmatic scroll - nearBottom: \(isNearBottomEdge), handled: \(hasHandledProgrammaticScrollNearEdge)")
                return
            }
            hasHandledProgrammaticScrollNearEdge = true
            MEGALogDebug("[\(type(of: self))] Handling programmatic scroll near bottom edge")
        }
        
        isPaginationInProgress = true
        defer { isPaginationInProgress = false }
        
        guard totalVisibleItems > pageSize,
              shouldLoadMore(for: visibleIndex, totalItems: totalVisibleItems) else { return }
        
        let itemIndex = (firstPageIndex * pageSize) + visibleIndex
        let currentPageIndex = itemIndex / pageSize
        
        guard lastProcessedPageIndex != currentPageIndex else { return }
        lastProcessedPageIndex = currentPageIndex
        
        MEGALogDebug("[\(type(of: self))] Loading page \(currentPageIndex) (itemIndex: \(itemIndex))")
        
        guard let update = await paginationManager.loadPageIfNeeded(
            itemIndex: itemIndex
        ) else {
            MEGALogDebug("[\(type(of: self))] No new data for page \(currentPageIndex)")
            return
        }
        
        applyInQueueUpdate(update)
        hasHandledProgrammaticScrollNearEdge = false
    }
    
    func isNearEdge(visibleIndex: Int, totalItems: Int) -> Bool {
        visibleIndex < pageSize || visibleIndex >= (totalItems - pageSize)
    }
    
    private func applyInQueueUpdate(_ update: PaginationUpdate) {
        firstPageIndex = update.firstPageIndex
        lastPageIndex = update.lastPageIndex
        
        let viewModels = update.items.map {
            CameraUploadInQueueRowViewModel(
                assetUploadEntity: $0,
                cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
                photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
                thumbnailSize: thumbnailSize)
        }
        
        if isInitialLoad {
            inQueueSnapshotUpdate = .initial(viewModels)
        } else {
            inQueueSnapshotUpdate = .updated(viewModels)
        }
    }
    
    private func shouldLoadMore(for visibleIndex: Int, totalItems: Int) -> Bool {
        let threshold = Int(Double(pageSize) * 2.5)
        return visibleIndex < threshold || visibleIndex >= (totalItems - threshold)
    }
}
