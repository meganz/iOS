import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGASdk
import MEGAUIComponent
import Search

@MainActor
@objc public final class FolderLinkViewModel: NSObject, ViewModelType {
    public enum Action: ActionType {
        case startLoadingFolderLink
        case confirmDecryptionKey(String)
        case monitorNodeUpdates
        case cancelConfirmingDecryptionKey
        case trackSendToChatFolderLinkNoAccountLogged
        case trackSendToChatFolderLink
        case saveToPhotos([NodeEntity])
        case updateViewMode(ViewModePreferenceEntity)
        case onSortHeaderViewPressed
    }
    
    public enum Command: CommandType {
        case rootFolderLinkLoaded
        case nodeDownloadTransferFinish(HandleEntity)
        case nodesUpdate([NodeEntity])
        case linkUnavailable(FolderLinkUnavailableReason)
        case invalidDecryptionKey
        case decryptionKeyRequired
        case fileAttributeUpdate(HandleEntity)
        case endEditingMode
        case showSaveToPhotosError(String)
        case setViewMode(ViewModePreferenceEntity)
    }
    
    public var invokeCommand: ((Command) -> Void)?
    public func dispatch(_ action: Action) {
        switch action {
        case .startLoadingFolderLink:
            startLoadingFolderLink()
        case let .confirmDecryptionKey(key):
            confirmDecryptionKey(key)
        case .cancelConfirmingDecryptionKey:
            folderLinkFlowUseCase.stop()
        case .monitorNodeUpdates:
            startMonitoringUpdates()
        case .trackSendToChatFolderLink:
            trackSendToChatFolderLinkEvent()
        case .trackSendToChatFolderLinkNoAccountLogged:
            trackSendToChatFolderLinkNoAccountLoggedEvent()
        case .saveToPhotos(let nodes):
            saveToPhotos(nodes)
        case .updateViewMode(let viewMode):
            updateViewMode(viewMode)
        case .onSortHeaderViewPressed:
            tracker.trackAnalyticsEvent(with: SortButtonPressedEvent())
        }
    }
    
    private let publicLink: String
    private let folderLinkUseCase: any FolderLinkUseCaseProtocol
    private let folderLinkFlowUseCase: any FolderLinkFlowUseCaseProtocol
    private let saveMediaUseCase: any SaveMediaToPhotosUseCaseProtocol
    private let tracker: any AnalyticsTracking

    private var subscriptions: Set<AnyCancellable> = []

    private var viewMode: ViewModePreferenceEntity {
        didSet {
            viewModeHeaderViewModel.selectedViewMode = viewMode == .list ? .list : .grid
        }
    }

    lazy var viewModeHeaderViewModel: SearchResultsHeaderViewModeViewModel = {
        SearchResultsHeaderViewModeViewModel(
            selectedViewMode: viewMode == .list ? .list : .grid,
            availableViewModes: [.list, .grid]
        )
    }()

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
    
    private var monitorRequestFinishUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    init(
        publicLink: String,
        folderLinkUseCase: some FolderLinkUseCaseProtocol,
        folderLinkFlowUseCase: some FolderLinkFlowUseCaseProtocol,
        saveMediaUseCase: some SaveMediaToPhotosUseCaseProtocol,
        viewMode: ViewModePreferenceEntity,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.publicLink = publicLink
        self.folderLinkFlowUseCase = folderLinkFlowUseCase
        self.folderLinkUseCase = folderLinkUseCase
        self.saveMediaUseCase = saveMediaUseCase
        self.tracker = tracker
        self.viewMode = viewMode
        super.init()
        listenToViewModesUpdates()
    }
    
    deinit {
        monitorCompletedDownloadTransferTask?.cancel()
        monitorNodeUpdatesTask?.cancel()
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
        
        monitorRequestFinishUpdatesTask = Task { [weak self, folderLinkUseCase] in
            for await nodeHandle in folderLinkUseCase.fileAttributesUpdates {
                guard !Task.isCancelled else { break }
                self?.invokeCommand?(.fileAttributeUpdate(nodeHandle))
            }
        }
    }
    
    /// Only run once per folder link, no need keep track the task, just need weak self for avoid prolong self lifetime
    private func startLoadingFolderLink() {
        Task { [weak self, folderLinkFlowUseCase, publicLink] in
            do throws(FolderLinkFlowErrorEntity) {
                try await folderLinkFlowUseCase.initialStart(with: publicLink)
                guard !Task.isCancelled else { return }
                self?.invokeCommand?(.rootFolderLinkLoaded)
            } catch {
                self?.handleFolderLinkFlowError(error)
            }
        }
    }
    
    /// Next task only starts when previous task completed.
    /// So no need keep track the task, just need weak self for avoid prolong self lifetime
    private func confirmDecryptionKey(_ key: String) {
        Task { [weak self, folderLinkFlowUseCase, publicLink] in
            do throws(FolderLinkFlowErrorEntity) {
                try await folderLinkFlowUseCase.confirmDecryptionKey(with: publicLink, decryptionKey: key)
                guard !Task.isCancelled else { return }
                self?.invokeCommand?(.rootFolderLinkLoaded)
            } catch {
                self?.handleFolderLinkFlowError(error)
            }
        }
    }
    
    private func handleFolderLinkFlowError(_ error: FolderLinkFlowErrorEntity) {
        switch error {
        case .invalidDecryptionKey:
            invokeCommand?(.invalidDecryptionKey)
        case .missingDecryptionKey:
            invokeCommand?(.decryptionKeyRequired)
        case let .linkUnavailable(reason):
            invokeCommand?(.linkUnavailable(reason))
        }
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

    private func updateViewMode(_ viewMode: ViewModePreferenceEntity) {
        self.viewMode = viewMode
    }

    private func listenToViewModesUpdates() {
        viewModeHeaderViewModel
            .$selectedViewMode
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .seconds(0.4), scheduler: DispatchQueue.main) // This is needed to prevent a crash because the header is removed.
            .map { $0 == .list ? .list : .thumbnail }
            .sink { [weak self] in
                self?.invokeCommand?(.setViewMode($0))
                self?.triggerEvent(for: $0)
            }
            .store(in: &subscriptions)
    }

    private func triggerEvent(for viewMode: ViewModePreferenceEntity) {
        switch viewMode {
        case .list:
            tracker.trackAnalyticsEvent(with: ViewModeListMenuItemEvent())
        case .thumbnail:
            tracker.trackAnalyticsEvent(with: ViewModeGridMenuItemEvent())
        default:
            break
        }
    }
}
