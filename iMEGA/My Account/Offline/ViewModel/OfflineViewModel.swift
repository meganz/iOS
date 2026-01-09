import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAFoundation
import MEGASwift
import MEGAUIComponent
import Search

enum OfflineViewAction: ActionType {
    case onViewAppear
    case onViewWillDisappear
    case removeOfflineItems(_ items: [URL])
    case onSortHeaderViewPressed
    case updateViewModeHeader(viewMode: SearchResultsViewMode)
}

@MainActor
final class OfflineViewModel: NSObject, ViewModelType {
    enum Command: CommandType, Equatable {
        case reloadUI
    }
    
    var invokeCommand: ((Command) -> Void)?
    private let throttler: any Throttleable
    private let offlineUseCase: any OfflineUseCaseProtocol
    private let megaStore: MEGAStore
    private let fileManager: FileManager
    private let documentsDirectoryPath: String?
    private var nodeDownloadMonitoringTask: Task<Void, any Error>? {
        didSet {
            oldValue?.cancel()
        }
    }

    private let sortHeaderCoordinator: SortHeaderCoordinator
    private let userDefaults: UserDefaults
    private let toggleViewModePreferenceHandler: (ViewModePreferenceEntity) -> Void
    private var subscriptions: Set<AnyCancellable> = []
    private let tracker: any AnalyticsTracking

    var sortHeaderViewModel: SortHeaderViewModel {
        sortHeaderCoordinator.headerViewModel
    }

    private var viewMode: ViewModePreferenceEntity {
        ViewModePreferenceEntity(rawValue: userDefaults.integer(forKey: MEGAViewModePreference)) ?? .list
    }

    lazy var viewModeHeaderViewModel: SearchResultsHeaderViewModeViewModel = {
        SearchResultsHeaderViewModeViewModel(
            selectedViewMode: viewMode == .list ? .list : .grid,
            availableViewModes: [.list, .grid]
        )
    }()

    // MARK: - Init
    init(
        offlineUseCase: some OfflineUseCaseProtocol,
        megaStore: MEGAStore,
        sortHeaderCoordinator: SortHeaderCoordinator,
        fileManager: FileManager = FileManager.default,
        userDefaults: UserDefaults = .standard,
        documentsDirectoryPath: String? = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
        throttler: some Throttleable = Throttler(timeInterval: 1.0),
        tracker: any AnalyticsTracking = DIContainer.tracker,
        toggleViewModePreferenceHandler: @escaping (ViewModePreferenceEntity) -> Void
    ) {
        self.offlineUseCase = offlineUseCase
        self.megaStore = megaStore
        self.sortHeaderCoordinator = sortHeaderCoordinator
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        self.documentsDirectoryPath = documentsDirectoryPath
        self.throttler = throttler
        self.tracker = tracker
        self.toggleViewModePreferenceHandler = toggleViewModePreferenceHandler

        super.init()

        listenToViewModesUpdates()
    }

    // MARK: - Dispatch actions
    
    func dispatch(_ action: OfflineViewAction) {
        switch action {
        case .onViewAppear:
            startMonitoringNodeDownloadCompletionUpdates()
        case .onViewWillDisappear:
            stopMonitoringNodeDownloadCompletionUpdates()
        case .removeOfflineItems(let items):
            removeOfflineItems(items)
        case .onSortHeaderViewPressed:
            tracker.trackAnalyticsEvent(with: SortButtonPressedEvent())
        case .updateViewModeHeader(let newViewMode):
            guard viewModeHeaderViewModel.selectedViewMode != newViewMode else { return }
            viewModeHeaderViewModel.selectedViewMode = newViewMode
        }
    }

    // MARK: - Subscriptions
    
    private func startMonitoringNodeDownloadCompletionUpdates() {
        nodeDownloadMonitoringTask = Task { [weak self, offlineUseCase] in
            for await _ in offlineUseCase.nodeDownloadCompletionUpdates {
                try Task.checkCancellation()
                self?.throttler.start { @Sendable in
                    Task { @MainActor in
                        self?.invokeCommand?(.reloadUI)
                    }
                }
            }
        }
    }
    
    private func stopMonitoringNodeDownloadCompletionUpdates() {
        nodeDownloadMonitoringTask = nil
    }

    /// Removes the specified offline items.
    /// - Parameter items: An array of URLs representing the offline items to be removed.
    private func removeOfflineItems(_ items: [URL]) {
        Task {
            await items.taskGroup(maxConcurrentTasks: 3) { url in
                await self.removeOfflineItem(url: url)
            }
            
            invokeCommand?(.reloadUI)
            QuickAccessWidgetManager.reloadWidgetContentOfKind(kind: MEGAOfflineQuickAccessWidget)
        }
    }
    
    private func removeOfflineItem(url: URL) async {
        do {
            try await offlineUseCase.removeItem(at: url)
            removeLogFromSharedSandboxIfNeeded(path: url.path)
            let relativePath = offlineUseCase.relativePathToDocumentsDirectory(for: url)
            if url.hasDirectoryPath {
                megaStore.deleteOfflineAppearancePreference(path: relativePath)
            }
            if let offlineNode = megaStore.fetchOfflineNode(withPath: relativePath) {
                megaStore.remove(offlineNode)
            }
        } catch {
            MEGALogError("Remove item at \(url) failed with \(error)")
        }
    }

    private func removeLogFromSharedSandboxIfNeeded(path: String) {
        removeLogFromSharedSandbox(path: path, extensionLogName: documentProviderLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: fileProviderLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: shareExtensionLog)
        removeLogFromSharedSandbox(path: path, extensionLogName: notificationServiceExtensionLog)
    }
    
    private func removeLogFromSharedSandbox(path: String, extensionLogName: String) {
        let logsPath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)?.appendingPathComponent(MEGAExtensionLogsFolder).path
        let documentsPath = documentsDirectoryPath?.appending("/")
        let extensionLogFile = documentsPath?.append(pathComponent: extensionLogName)
        if let logsPath, extensionLogFile == path {
            do {
                try fileManager.removeItem(atPath: logsPath.append(pathComponent: extensionLogName))
            } catch {
                MEGALogError("[File manager] remove item at path failed with error \(error)")
            }
        }
    }

    private func listenToViewModesUpdates() {
        viewModeHeaderViewModel
            .$selectedViewMode
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .seconds(0.4), scheduler: DispatchQueue.main) // This is needed to prevent a crash because the header is removed.
            .sink { [weak self] in
                guard let self else { return }
                let viewMode: ViewModePreferenceEntity = $0 == .list ? .list : .thumbnail
                toggleViewModePreferenceHandler(viewMode)
                triggerEvent(for: viewMode)
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
