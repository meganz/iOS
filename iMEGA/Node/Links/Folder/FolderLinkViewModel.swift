import MEGADomain

@MainActor
@objc final class FolderLinkViewModel: NSObject, ObservableObject {
    typealias NodeDownloadTransferFinishHandler = @MainActor (HandleEntity) -> Void
    typealias NodeUpdatesHandler = @MainActor ([NodeEntity]) -> Void
    
    private let folderLinkUseCase: any FolderLinkUseCaseProtocol

    private var monitorCompletedDownloadTransferTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    private var monitorNodeUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    var onNodeDownloadTransferFinish: NodeDownloadTransferFinishHandler?
    var onNodeUpdates: NodeUpdatesHandler?
    
    init(folderLinkUseCase: some FolderLinkUseCaseProtocol) {
        self.folderLinkUseCase = folderLinkUseCase
    }
    
    @objc func onViewAppear() {
        monitorCompletedDownloadTransferTask = Task { [weak self, folderLinkUseCase] in
            for await nodeHandle in folderLinkUseCase.completedDownloadTransferUpdates {
                self?.onNodeDownloadTransferFinish?(nodeHandle)
            }
        }
        
        monitorNodeUpdatesTask = Task { [weak self, folderLinkUseCase] in
            for await nodeEntities in folderLinkUseCase.nodeUpdates {
                self?.onNodeUpdates?(nodeEntities)
            }
        }
    }
    
    @objc func onViewDisappear() {
        monitorCompletedDownloadTransferTask = nil
        monitorNodeUpdatesTask = nil
    }
}
