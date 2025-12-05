import MEGAAppPresentation
import MEGADomain
import MEGARepo

@MainActor
final class CameraUploadProgressTableViewModel: ObservableObject {
    enum SnapshotUpdate: Equatable {
        case loading(numberOfRowsPerSection: Int)
        case initialLoad(inProgress: [CameraUploadInProgressRowViewModel], inQueue: [CameraUploadInQueueRowViewModel])
        case inProgressItemAdded(CameraUploadInProgressRowViewModel)
        case inQueueUpdated([CameraUploadInQueueRowViewModel])
        case itemRemoved(CameraUploadLocalIdentifierEntity)
    }
    @Published private(set) var snapshotUpdate: SnapshotUpdate = .loading(numberOfRowsPerSection: 4)
    
    private let cameraUploadProgressUseCase: any CameraUploadProgressUseCaseProtocol
    private let cameraUploadFileDetailsUseCase: any CameraUploadFileDetailsUseCaseProtocol
    private let photoLibraryThumbnailProvider: any PhotoLibraryThumbnailProviderProtocol
    private let thumbnailSize: CGSize = .init(width: 32, height: 32)
    private let paginationManager: any CameraUploadPaginationManagerProtocol
    private let pageSize: Int
    
    private var firstPageIndex: Int = 0
    private var lastPageIndex: Int = 0
    private var lastProcessedPageIndex: Int?
    private(set) var isPaginationInProgress = false
    private var lastScrollPosition: Int?
    
    let rowHeight: CGFloat = 60
    
    init(
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol,
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol,
        photoLibraryThumbnailProvider: some PhotoLibraryThumbnailProviderProtocol,
        paginationManager: some CameraUploadPaginationManagerProtocol
    ) {
        self.cameraUploadProgressUseCase = cameraUploadProgressUseCase
        self.cameraUploadFileDetailsUseCase = cameraUploadFileDetailsUseCase
        self.photoLibraryThumbnailProvider = photoLibraryThumbnailProvider
        self.paginationManager = paginationManager
        self.pageSize = paginationManager.pageSize
    }
    
    deinit {
        photoLibraryThumbnailProvider.clearCache()
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
                photoLibraryThumbnailProvider.startCaching(
                    for: allLocalIdentifiers, targetSize: thumbnailSize)
            }
            
            let inProgressVMs = inProgress.map {
                CameraUploadInProgressRowViewModel(
                    fileEntity: $0,
                    cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                    photoLibraryThumbnailProvider: photoLibraryThumbnailProvider,
                    thumbnailSize: thumbnailSize)
            }
            
            try Task.checkCancellation()
            
            let inQueueVMs = inQueueUpdate.items.map {
                CameraUploadInQueueRowViewModel(
                    assetUploadEntity: $0,
                    cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
                    photoLibraryThumbnailProvider: photoLibraryThumbnailProvider,
                    thumbnailSize: thumbnailSize)
            }
            try Task.checkCancellation()
            
            snapshotUpdate = .initialLoad(inProgress: inProgressVMs, inQueue: inQueueVMs)
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
                
                snapshotUpdate = .inProgressItemAdded(.init(
                    fileEntity: fileEntity,
                    cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                    photoLibraryThumbnailProvider: photoLibraryThumbnailProvider,
                    thumbnailSize: thumbnailSize))
                
                await paginationManager.removeItemFromPages(localIdentifier: phaseEvent.assetIdentifier)
            case .completed:
                snapshotUpdate = .itemRemoved(phaseEvent.assetIdentifier)
                
                photoLibraryThumbnailProvider.stopCaching(
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
        guard lastScrollPosition != visibleIndex else {
            return
        }
        
        lastScrollPosition = visibleIndex
        
        guard totalVisibleItems > pageSize else { return }
        
        let shouldPaginate = if isUserInitiated {
            shouldLoadMore(for: visibleIndex, totalItems: totalVisibleItems)
        } else {
            isNearEdge(visibleIndex: visibleIndex, totalItems: totalVisibleItems)
        }
        guard shouldPaginate else { return }
        
        let itemIndex = (firstPageIndex * pageSize) + visibleIndex
        let currentPageIndex = itemIndex / pageSize
        
        guard lastProcessedPageIndex != currentPageIndex else { return }
        
        isPaginationInProgress = true
        defer { isPaginationInProgress = false }
        
        lastProcessedPageIndex = currentPageIndex
        
        MEGALogDebug("[\(type(of: self))] Loading page \(currentPageIndex) (itemIndex: \(itemIndex))")
        
        guard let update = await paginationManager.loadPageIfNeeded(
            itemIndex: itemIndex
        ) else {
            MEGALogDebug("[\(type(of: self))] No new data for page \(currentPageIndex)")
            return
        }
        
        applyInQueueUpdate(update)
    }
    
    func isNearEdge(visibleIndex: Int, totalItems: Int) -> Bool {
        visibleIndex < pageSize || visibleIndex >= (totalItems - pageSize)
    }
    
    func reset() async {
        await paginationManager.reset()
        snapshotUpdate = .loading(numberOfRowsPerSection: 4)
        
        lastProcessedPageIndex = nil
        lastScrollPosition = nil
        isPaginationInProgress = false
    }
    
    private func applyInQueueUpdate(_ update: PaginationUpdate) {
        firstPageIndex = update.firstPageIndex
        lastPageIndex = update.lastPageIndex
        
        let viewModels = update.items.map {
            CameraUploadInQueueRowViewModel(
                assetUploadEntity: $0,
                cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
                photoLibraryThumbnailProvider: photoLibraryThumbnailProvider,
                thumbnailSize: thumbnailSize)
        }
        
        snapshotUpdate = .inQueueUpdated(viewModels)
    }
    
    private func shouldLoadMore(for visibleIndex: Int, totalItems: Int) -> Bool {
        let edgeThreshold = max(pageSize / 2, 10)
        let isNearTopEdge = visibleIndex < edgeThreshold
        let isNearBottomEdge = visibleIndex >= (totalItems - edgeThreshold)
        return (isNearTopEdge || isNearBottomEdge) && totalItems >= pageSize
    }
}
