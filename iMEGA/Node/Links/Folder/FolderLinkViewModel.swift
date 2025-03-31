import MEGADomain

@MainActor
@objc final class FolderLinkViewModel: NSObject, ObservableObject {
    typealias NodeDownloadTransferFinishHandler = @MainActor (HandleEntity) -> Void
    
    private let folderLinkUseCase: any FolderLinkUseCaseProtocol

    private var monitorCompletedDownloadTransferTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    var onNodeDownloadTransferFinish: NodeDownloadTransferFinishHandler?

    init(folderLinkUseCase: some FolderLinkUseCaseProtocol) {
        self.folderLinkUseCase = folderLinkUseCase
    }
    
    @objc func onViewAppear() {
        monitorCompletedDownloadTransferTask = Task { [weak self, folderLinkUseCase] in
            for await nodeHandle in folderLinkUseCase.completedDownloadTransferUpdates {
                self?.onNodeDownloadTransferFinish?(nodeHandle)
            }
        }
    }
    
    @objc func onViewDisappear() {
        monitorCompletedDownloadTransferTask = nil
    }
}
