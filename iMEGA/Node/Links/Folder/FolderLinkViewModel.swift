import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

@MainActor
@objc public final class FolderLinkViewModel: NSObject, ViewModelType {
    public enum Action: ActionType {
        case onViewDidLoad
        case trackSendToChatFolderLinkNoAccountLogged
        case trackSendToChatFolderLink
        case saveToPhotos([NodeEntity])
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
        case endEditingMode
        case showSaveToPhotosError(String)
    }
    
    public var invokeCommand: ((Command) -> Void)?
    public func dispatch(_ action: Action) {
        switch action {
        case .onViewDidLoad:
            startMonitoringUpdates()
        case .trackSendToChatFolderLink:
            trackSendToChatFolderLinkEvent()
        case .trackSendToChatFolderLinkNoAccountLogged:
            trackSendToChatFolderLinkNoAccountLoggedEvent()
        case .saveToPhotos(let nodes):
            saveToPhotos(nodes)
        }
    }
    
    private let folderLinkUseCase: any FolderLinkUseCaseProtocol
    private let saveMediaUseCase: any SaveMediaToPhotosUseCaseProtocol
    private let tracker: any AnalyticsTracking

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
    
    init(
        folderLinkUseCase: some FolderLinkUseCaseProtocol,
        saveMediaUseCase: some SaveMediaToPhotosUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.folderLinkUseCase = folderLinkUseCase
        self.saveMediaUseCase = saveMediaUseCase
        self.tracker = tracker
        super.init()
    }
    
    deinit {
        monitorCompletedDownloadTransferTask?.cancel()
        monitorNodeUpdatesTask?.cancel()
        monitorFetchNodesRequestStartUpdatesTask?.cancel()
        monitorRequestFinishUpdatesTask?.cancel()
    }
    
    private func startMonitoringUpdates() {
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
    
    private func trackSendToChatFolderLinkNoAccountLoggedEvent() {
        tracker.trackAnalyticsEvent(with: SendToChatFolderLinkNoAccountLoggedButtonPressedEvent())
    }

    private func trackSendToChatFolderLinkEvent() {
        tracker.trackAnalyticsEvent(with: SendToChatFolderLinkButtonPressedEvent())
    }
    
    private func saveToPhotos(_ nodes: [NodeEntity]) {
        invokeCommand?(.endEditingMode)
        Task { @MainActor in
            do {
                try await saveMediaUseCase.saveToPhotos(nodes: nodes)
            } catch let error as SaveMediaToPhotosErrorEntity {
                if error != .cancelled {
                    invokeCommand?(.showSaveToPhotosError(error.localizedDescription))
                }
            } catch {
                MEGALogError("Error saving photos: \(error.localizedDescription)")
            }
        }
    }
}
