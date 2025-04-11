import MEGAAppPresentation
import MEGADomain

@MainActor
@objc public final class FolderLinkViewModel: NSObject, ViewModelType {
    public enum Action: ActionType {
        case onViewAppear
        case onViewDisappear
    }
    
    public enum Command: CommandType {
        case nodeDownloadTransferFinish(HandleEntity)
        case nodesUpdate([NodeEntity])
        case linkUnavailable(FolderLinkUnavailableReason)
        case invalidDecryptionKey
        case decryptionKeyRequired
        case loginDone
        case fetchNodesDone(validKey: Bool)
        case fetchNodesStarted
        case fetchNodesFailed
        case logoutDone
        case fileAttributeUpdate(HandleEntity)
    }
    
    public var invokeCommand: ((Command) -> Void)?
    public func dispatch(_ action: Action) {
        switch action {
        case .onViewAppear:
            onViewAppear()
        case .onViewDisappear:
            onViewDisappear()
        }
    }
    
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
    
    private var monitorFetchNodesRequestStartUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    private var monitorRequestFinishUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    init(folderLinkUseCase: some FolderLinkUseCaseProtocol) {
        self.folderLinkUseCase = folderLinkUseCase
    }
    
    private func onViewAppear() {
        monitorCompletedDownloadTransferTask = Task { [weak self, folderLinkUseCase] in
            for await nodeHandle in folderLinkUseCase.completedDownloadTransferUpdates {
                guard !Task.isCancelled else { break }
                self?.invokeCommand?(.nodeDownloadTransferFinish(nodeHandle))
            }
        }
        
        monitorNodeUpdatesTask = Task { [weak self, folderLinkUseCase] in
            for await nodeEntities in folderLinkUseCase.nodeUpdates {
                guard !Task.isCancelled else { break }
                self?.invokeCommand?(.nodesUpdate(nodeEntities))
            }
        }
        
        monitorFetchNodesRequestStartUpdatesTask = Task { [weak self, folderLinkUseCase] in
            for await _ in folderLinkUseCase.fetchNodesRequestStartUpdates {
                guard !Task.isCancelled else { break }
                self?.invokeCommand?(.fetchNodesStarted)
            }
        }
        
        monitorRequestFinishUpdatesTask = Task { [weak self, folderLinkUseCase] in
            for await result in folderLinkUseCase.requestFinishUpdates {
                guard !Task.isCancelled else { break }
                switch result {
                case .success(let requestEntity):
                    switch requestEntity.type {
                    case .login:
                        self?.invokeCommand?(.loginDone)
                    case .fetchNodes:
                        self?.invokeCommand?(.fetchNodesDone(validKey: !requestEntity.flag))
                    case .logout:
                        self?.handleLogoutDone()
                    case .getAttrFile:
                        self?.invokeCommand?(.fileAttributeUpdate(requestEntity.nodeHandle))
                    default:
                        break
                    }
                case .failure(let folderLinkErrorEntity):
                    switch folderLinkErrorEntity {
                    case .linkUnavailable(let reason):
                        self?.invokeCommand?(.linkUnavailable(reason))
                    case .invalidDecryptionKey:
                        self?.invokeCommand?(.invalidDecryptionKey)
                    case .decryptionKeyRequired:
                        self?.invokeCommand?(.decryptionKeyRequired)
                    case .fetchNodesFailed:
                        self?.invokeCommand?(.fetchNodesFailed)
                    }
                }
            }
        }
    }
    
    private func handleLogoutDone() {
        invokeCommand?(.logoutDone)
        monitorNodeUpdatesTask = nil
        monitorFetchNodesRequestStartUpdatesTask = nil
        monitorRequestFinishUpdatesTask = nil
    }
    
    private func onViewDisappear() {
        monitorCompletedDownloadTransferTask = nil
        monitorNodeUpdatesTask = nil
        monitorFetchNodesRequestStartUpdatesTask = nil
        monitorRequestFinishUpdatesTask = nil
    }
}
